package edu.umd.cs.bachuai13

import org.slf4j.Logger
import org.slf4j.LoggerFactory

import com.google.common.collect.Iterables

import edu.umd.cs.bachuai13.util.DataOutputter;
import edu.umd.cs.bachuai13.util.ExperimentConfigGenerator;
import edu.umd.cs.bachuai13.util.FoldUtils;
import edu.umd.cs.bachuai13.util.WeightLearner;
import edu.umd.cs.psl.application.inference.MPEInference
import edu.umd.cs.psl.application.learning.weight.maxlikelihood.MaxLikelihoodMPE
import edu.umd.cs.psl.application.learning.weight.maxlikelihood.MaxPseudoLikelihood
import edu.umd.cs.psl.application.learning.weight.maxmargin.MaxMargin
import edu.umd.cs.psl.application.learning.weight.maxmargin.MaxMargin.LossBalancingType
import edu.umd.cs.psl.application.learning.weight.maxmargin.MaxMargin.NormScalingType
import edu.umd.cs.psl.application.learning.weight.random.FirstOrderMetropolisRandOM
import edu.umd.cs.psl.application.learning.weight.random.HardEMRandOM
import edu.umd.cs.psl.config.*
import edu.umd.cs.psl.core.*
import edu.umd.cs.psl.core.inference.*
import edu.umd.cs.psl.database.DataStore
import edu.umd.cs.psl.database.Database
import edu.umd.cs.psl.database.DatabasePopulator
import edu.umd.cs.psl.database.DatabaseQuery
import edu.umd.cs.psl.database.Partition
import edu.umd.cs.psl.database.ResultList
import edu.umd.cs.psl.database.rdbms.RDBMSDataStore
import edu.umd.cs.psl.database.rdbms.driver.H2DatabaseDriver
import edu.umd.cs.psl.database.rdbms.driver.H2DatabaseDriver.Type
import edu.umd.cs.psl.evaluation.result.*
import edu.umd.cs.psl.evaluation.statistics.DiscretePredictionComparator
import edu.umd.cs.psl.evaluation.statistics.DiscretePredictionStatistics
import edu.umd.cs.psl.evaluation.statistics.filter.MaxValueFilter
import edu.umd.cs.psl.groovy.*
import edu.umd.cs.psl.model.Model
import edu.umd.cs.psl.model.argument.ArgumentType
import edu.umd.cs.psl.model.argument.GroundTerm
import edu.umd.cs.psl.model.argument.UniqueID
import edu.umd.cs.psl.model.argument.Variable
import edu.umd.cs.psl.model.atom.GroundAtom
import edu.umd.cs.psl.model.atom.QueryAtom
import edu.umd.cs.psl.model.atom.RandomVariableAtom
import edu.umd.cs.psl.model.kernel.CompatibilityKernel
import edu.umd.cs.psl.model.parameters.PositiveWeight
import edu.umd.cs.psl.model.parameters.Weight
import edu.umd.cs.psl.ui.loading.*
import edu.umd.cs.psl.util.database.Queries


/*** CONFIGURATION PARAMETERS ***/

def dataSet = args[0];
def modelType = args[1];
def fold = args[2];

if (dataSet.equals("citeseer")) {
	dataPath = "./data/citeseer/" + fold
	numCategories = 6
	labelFileTruth = "hasCat_truth.txt"
	labelFileTargets = "hasCat_targets.txt"
	labelFileObs = "hasCat_obs.txt"
	linkFile = "link_obs.txt"
}
else if (dataSet.equals("cora")) {
	dataPath = "./data/cora/" + fold
	numCategories = 7
	labelFileTruth = "hasCat_truth.txt"
	labelFileTargets = "hasCat_targets.txt"
	labelFileObs = "hasCat_obs.txt"
	linkFile = "link_obs.txt"
}
else
	throw new IllegalArgumentException("Unrecognized data set: "
		+ dataSet + ". Options are 'citeseer' and 'cora.'");

sq = (!modelType.equals("linear") ? true : false)
usePerCatRules = true
double seedRatio = 0.5 // ratio of observed labels
Random rand = new Random(0) // used to seed observed data
trainTestRatio = 0.5 // ratio of train to test splits (random)
filterRatio = 1.0 // ratio of documents to keep (throw away the rest)

Logger log = LoggerFactory.getLogger(this.class)

ConfigManager cm = ConfigManager.getManager()
ConfigBundle cb = cm.getBundle(dataSet)

def defaultPath = System.getProperty("java.io.tmpdir")
String dbpath = cb.getString("dbpath", defaultPath + File.separator + "psl-" + dataSet)
DataStore data = new RDBMSDataStore(new H2DatabaseDriver(Type.Disk, dbpath, true), cb)

/**
 * SET UP CONFIGS
 */

ExperimentConfigGenerator configGenerator = new ExperimentConfigGenerator(dataSet);

/*
 * SET MODEL TYPES
 *
 * Options:
 * "quad" HL-MRF-Q
 * "linear" HL-MRF-L
 * "bool" MRF
 */
configGenerator.setModelTypes([modelType]);

/*
 * SET LEARNING ALGORITHMS
 *
 * Options:
 * "MLE" (MaxLikelihoodMPE)
 * "MPLE" (MaxPseudoLikelihood)
 * "MM" (MaxMargin)
 */
//configGenerator.setLearningMethods(["MLE", "MPLE", "MM"]);
configGenerator.setLearningMethods(["MM"]);

/* MLE/MPLE options */
configGenerator.setVotedPerceptronStepCounts([100]);
configGenerator.setVotedPerceptronStepSizes([(double) 5.0]);

/* MM options */
configGenerator.setMaxMarginSlackPenalties([(double) 0.1]);
configGenerator.setMaxMarginLossBalancingTypes([LossBalancingType.NONE]);
configGenerator.setMaxMarginNormScalingTypes([NormScalingType.NONE]);
configGenerator.setMaxMarginSquaredSlackValues([false]);

List<ConfigBundle> configs = configGenerator.getConfigs();

/*
 * DEFINE MODEL
 */

PSLModel m = new PSLModel(this, data)

// predicates
m.add predicate: "HasCat", types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
m.add predicate: "Link", types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
m.add predicate: "Cat", types: [ArgumentType.UniqueID]

// prior
m.add rule : ~(HasCat(A,N)), weight: 0.001, squared: sq

// per-cat rules
for (int i = 0; i < numCategories; i++)  {
	UniqueID cat = data.getUniqueID(i+1)
	m.add rule : ( HasCat(A, cat) & Link(A,B)) >> HasCat(B, cat), weight: 1.0, squared: sq
	m.add rule : ( HasCat(A, cat) & Link(B,A)) >> HasCat(B, cat), weight: 1.0, squared: sq
}

// neighbor has cat => has cat
m.add rule : ( HasCat(A,C) & Link(A,B) & (A - B)) >> HasCat(B,C), weight: 1.0, squared: sq
m.add rule : ( HasCat(A,C) & Link(B,A) & (A - B)) >> HasCat(B,C), weight: 1.0, squared: sq

// ensure that HasCat sums to 1
m.add PredicateConstraint.Functional , on : HasCat

/* get all default weights. set during initialization above */
Map<CompatibilityKernel, Weight> weights = new HashMap<CompatibilityKernel, Weight>()
for (CompatibilityKernel k : Iterables.filter(m.getKernels(), CompatibilityKernel.class))
	weights.put(k, k.getWeight());

/*** LOAD DATA ***/
// Learn
Partition trainReadPartition = new Partition(0)
Partition trainWritePartition = new Partition(1)
Partition trainLabelPartition = new Partition(2)

// Eval
Partition testReadPartition = new Partition(3)
Partition testWritePartition = new Partition(4)
Partition testLabelPartition = new Partition(5)

def inserter
// Learn
inserter = data.getInserter(Link, trainReadPartition)
InserterUtils.loadDelimitedDataTruth(inserter, dataPath + "/learn/" + linkFile)
inserter = data.getInserter(HasCat, trainReadPartition)
InserterUtils.loadDelimitedDataTruth(inserter, dataPath + "/learn/" + labelFileObs)
inserter = data.getInserter(HasCat, trainWritePartition)
InserterUtils.loadDelimitedData(inserter, dataPath + "/learn/" + labelFileTargets)
inserter = data.getInserter(HasCat, trainLabelPartition)
InserterUtils.loadDelimitedDataTruth(inserter, dataPath + "/learn/" + labelFileTruth)

// Eval
inserter = data.getInserter(Link, testReadPartition)
InserterUtils.loadDelimitedDataTruth(inserter, dataPath + "/eval/" + linkFile)
inserter = data.getInserter(HasCat, testReadPartition)
InserterUtils.loadDelimitedDataTruth(inserter, dataPath + "/eval/" + labelFileObs)
inserter = data.getInserter(HasCat, testWritePartition)
InserterUtils.loadDelimitedData(inserter, dataPath + "/eval/" + labelFileTargets)
inserter = data.getInserter(HasCat, testLabelPartition)
InserterUtils.loadDelimitedDataTruth(inserter, dataPath + "/eval/" + labelFileTruth)

def keys = new HashSet<Variable>()
Set<Integer> trainingSeedKeys = new HashSet<Integer>()
Set<Integer> testingSeedKeys = new HashSet<Integer>()
Set<Integer> trainingKeys = new HashSet<Integer>()
Set<Integer> testingKeys = new HashSet<Integer>()
def queries = new HashSet<DatabaseQuery>()


/*
 * DEFINE PRIMARY KEY QUERIES FOR FOLD SPLITTING
 */
Variable document = new Variable("Document")
Variable linkedDocument = new Variable("LinkedDoc")
keys.add(document)
keys.add(linkedDocument)
queries.add(new DatabaseQuery(Link(document, linkedDocument).getFormula()))
queries.add(new DatabaseQuery(HasCat(document, A).getFormula()))

def partitionDocuments = new HashMap<Partition, Set<GroundTerm>>()

Set<GroundTerm> trainDocuments = FoldUtils.generateSplitGroundTerms(data, trainReadPartition, trainWritePartition,
		trainLabelPartition, queries, keys)

Set<GroundTerm> testDocuments = FoldUtils.generateSplitGroundTerms(data, testReadPartition, testWritePartition,
		testLabelPartition, queries, keys)

partitionDocuments.put(trainReadPartition, trainDocuments)
partitionDocuments.put(testReadPartition, testDocuments)

for (GroundTerm doc : partitionDocuments.get(trainReadPartition)) {
	trainingKeys.add(Integer.decode(doc.toString()))
}
for (GroundTerm doc : partitionDocuments.get(testReadPartition)) {
	testingKeys.add(Integer.decode(doc.toString()))
}

db = data.getDatabase(trainReadPartition)
ResultList list = db.executeQuery(new DatabaseQuery(HasCat(X, Y).getFormula()))
log.debug("{} instances of HasCat in {}", list.size(), trainReadPartition)
db.close()
db = data.getDatabase(testReadPartition)
list = db.executeQuery(new DatabaseQuery(HasCat(X, Y).getFormula()))
log.debug("{} instances of HasCat in {}", list.size(), testReadPartition)
db.close()

Map<String, DiscretePredictionStatistics> results = new HashMap<String, DiscretePredictionStatistics>()

/*** POPULATE DBs ***/

Database db;
DatabasePopulator dbPop;
Variable Category = new Variable("Category")
Variable Document = new Variable("Document")
Map<Variable, Set<GroundTerm>> substitutions = new HashMap<Variable, Set<GroundTerm>>()

/* categories */
Set<GroundTerm> categoryGroundings = new HashSet<GroundTerm>()
for (int i = 0; i <= numCategories; i++)
	categoryGroundings.add(data.getUniqueID(i + 1))
substitutions.put(Category, categoryGroundings)

/* populate HasCat */

toClose = [Link, Cat] as Set;
Database trainDB = data.getDatabase(trainWritePartition, toClose, trainReadPartition)
Database testDB = data.getDatabase(testWritePartition, toClose, testReadPartition)

dbPop = new DatabasePopulator(trainDB)
substitutions.put(Document, partitionDocuments.get(trainReadPartition))
dbPop.populate(new QueryAtom(HasCat, Document, Category), substitutions)

dbPop = new DatabasePopulator(testDB)
substitutions.put(Document, partitionDocuments.get(testReadPartition))
dbPop.populate(new QueryAtom(HasCat, Document, Category), substitutions)

toClose = [HasCat] as Set
Database labelsDB = data.getDatabase(trainLabelPartition, toClose)

def groundTruthDB = data.getDatabase(testLabelPartition, [HasCat] as Set)
DataOutputter.outputPredicate("output/" + dataSet + "/groundTruth" + fold + ".node", groundTruthDB, HasCat, ",", false, "nodeid,label")
groundTruthDB.close()

DataOutputter.outputPredicate("output/" + dataSet + "/groundTruth" + fold + ".directed", testDB, Link, ",", false, null)

/*** EXPERIMENT ***/

for (int configIndex = 0; configIndex < configs.size(); configIndex++) {
	ConfigBundle config = configs.get(configIndex);
	for (CompatibilityKernel k : Iterables.filter(m.getKernels(), CompatibilityKernel.class))
		k.setWeight(weights.get(k))

	/*
	 * Weight learning
	 */
	learn(m, trainDB, labelsDB, config, log)

	System.out.println("Learned model " + config.getString("name", "") + "\n" + m.toString())

	/* Inference on test set */
	Set<GroundAtom> allAtoms = Queries.getAllAtoms(testDB, HasCat)
	for (RandomVariableAtom atom : Iterables.filter(allAtoms, RandomVariableAtom))
		atom.setValue(0.0)
	/* For discrete MRFs, "MPE" inference will actually perform marginal inference */
	MPEInference mpe = new MPEInference(m, testDB, config)
	FullInferenceResult result = mpe.mpeInference()
	System.out.println("Objective: " + result.getTotalWeightedIncompatibility())

	/* Evaluation */
	def comparator = new DiscretePredictionComparator(testDB)
	groundTruthDB = data.getDatabase(testLabelPartition, [HasCat] as Set)
	comparator.setBaseline(groundTruthDB)
	comparator.setResultFilter(new MaxValueFilter(HasCat, 1))
	comparator.setThreshold(Double.MIN_VALUE) // treat best value as true as long as it is nonzero

	int totalTestExamples = testingKeys.size() * numCategories;
	System.out.println("totalTestExamples " + totalTestExamples)
	DiscretePredictionStatistics stats = comparator.compare(HasCat, totalTestExamples)
	System.out.println("F1 score " + stats.getF1(DiscretePredictionStatistics.BinaryClass.POSITIVE))

	results.put(config, stats)

	DataOutputter.outputClassificationPredictions("output/" + dataSet + "/" + config.getString("name", "") + fold + ".csv", testDB, HasCat, ",")

	groundTruthDB.close()
}
trainDB.close()

for (ConfigBundle config : configs) {
	def stats = results.get(config)
	def b = DiscretePredictionStatistics.BinaryClass.POSITIVE
	System.out.println("Method " + config.getString("name", "") + ", fold " + fold +", acc " + stats.getAccuracy() +
			", prec " + stats.getPrecision(b) + ", rec " + stats.getRecall(b) +
			", F1 " + stats.getF1(b) + ", correct " + stats.getCorrectAtoms().size() +
			", tp " + stats.tp + ", fp " + stats.fp + ", tn " + stats.tn + ", fn " + stats.fn)
}


public void learn(Model m, Database db, Database labelsDB, ConfigBundle config, Logger log) {
	switch(config.getString("learningmethod", "")) {
		case "MLE":
			MaxLikelihoodMPE mle = new MaxLikelihoodMPE(m, db, labelsDB, config)
			mle.learn()
			break
		case "MPLE":
			MaxPseudoLikelihood mple = new MaxPseudoLikelihood(m, db, labelsDB, config)
			mple.learn()
			break
		case "MM":
			MaxMargin mm = new MaxMargin(m, db, labelsDB, config)
			mm.learn()
			break
		default:
			throw new IllegalArgumentException("Unrecognized method.");
	}
}



