/*
 * All of the documentation and software included in the
 * Alchemy Software is copyrighted by Stanley Kok, Parag
 * Singla, Matthew Richardson, Pedro Domingos, Marc
 * Sumner, Hoifung Poon, and Daniel Lowd.
 *
 * Copyright [2004-07] Stanley Kok, Parag Singla, Matthew
 * Richardson, Pedro Domingos, Marc Sumner, Hoifung
 * Poon, and Daniel Lowd. All rights reserved.
 *
 * Contact: Pedro Domingos, University of Washington
 * (pedrod@cs.washington.edu).
 *
 * Redistribution and use in source and binary forms, with
 * or without modification, are permitted provided that
 * the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above
 * copyright notice, this list of conditions and the
 * following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the
 * above copyright notice, this list of conditions and the
 * following disclaimer in the documentation and/or other
 * materials provided with the distribution.
 *
 * 3. All advertising materials mentioning features or use
 * of this software must display the following
 * acknowledgment: "This product includes software
 * developed by Stanley Kok, Parag Singla, Matthew
 * Richardson, Pedro Domingos, Marc Sumner, Hoifung
 * Poon, and Daniel Lowd in the Department of Computer Science and
 * Engineering at the University of Washington".
 *
 * 4. Your publications acknowledge the use or
 * contribution made by the Software to your research
 * using the following citation(s):
 * Stanley Kok, Parag Singla, Matthew Richardson and
 * Pedro Domingos (2005). "The Alchemy System for
 * Statistical Relational AI", Technical Report,
 * Department of Computer Science and Engineering,
 * University of Washington, Seattle, WA.
 * http://www.cs.washington.edu/ai/alchemy.
 *
 * 5. Neither the name of the University of Washington nor
 * the names of its contributors may be used to endorse or
 * promote products derived from this software without
 * specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY OF WASHINGTON
 * AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE UNIVERSITY
 * OF WASHINGTON OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
#include <fstream>
#include <iostream>
#include <sstream>
#include "arguments.h"
#include "inferenceargs.h"
#include "lbfgsb.h"
#include "learnwts.h"
#include "maxmarginlearner.h"
#include "maxwalksat.h"
#include "ut-exactinfer.h"
#include "ut-ilpinfer.h"
#include "infer.h"

  //set to false to disable printing of clauses when they are counted during
  //generative learning
bool PRINT_CLAUSE_DURING_COUNT = true;

const double DISC_DEFAULT_STD_DEV = 2;
const double GEN_DEFAULT_STD_DEV = 100;

  // Variables for holding inference command line args are in inferenceargs.h
bool discLearn = false;
bool genLearn = false;
char* outMLNFile = NULL;
char* dbFiles = NULL;
char* nonEvidPredsStr = NULL;
bool noAddUnitClauses = false;
bool multipleDatabases = false;
bool initWithLogOdds = false;
bool isQueryEvidence = false;

bool aPeriodicMLNs = false;

bool noPrior = false;
double priorMean = 0;
double priorStdDev = -1;

  // Generative learning args
int maxIter = 10000;
double convThresh = 1e-5;
bool noEqualPredWt = false;

  // Max margin learning args
double maxSec  = 0;
int numIter = 1000;
int numMinIter = 5;
double maxMin  = 0;
double maxHour = 0;
double C = 1e+3;
double epsilon = 0.001;
int lossFunction = MaxMarginLearner::HAMMING;
double lossScale = 1;
bool withEM = false;
char* aInferStr = NULL;
int amwsMaxSubsequentSteps = -1;
bool debug = false;
bool useL1 = false;
bool nonMarginRescaling = false;
bool trainFileNamesInOneFile = false;
bool ignoreUnknownQueryAtom = false;
bool printLearnedWeightPerIter = false;
bool nonRecursive = false;

  // Inference arguments needed for disc. learning defined in inferenceargs.h
  // TODO: List the arguments common to learnwts and inference in
  // inferenceargs.h. This can't be done with a static array.
ARGS ARGS::Args[] =
{
    // BEGIN: Common arguments
  ARGS("i", ARGS::Req, ainMLNFiles,
       "Comma-separated input .mln files. (With the -multipleDatabases "
       "option, the second file to the last one are used to contain constants "
       "from different databases, and they correspond to the .db files "
       "specified with the -t option.)"),

  ARGS("cw", ARGS::Opt, aClosedWorldPredsStr,
       "Specified non-evidence atoms (comma-separated with no space) are "
       "closed world, otherwise, all non-evidence atoms are open world. Atoms "
       "appearing here cannot be query atoms and cannot appear in the -o "
       "option."),

  ARGS("ow", ARGS::Opt, aOpenWorldPredsStr,
       "Specified evidence atoms (comma-separated with no space) are open "
       "world, while other evidence atoms are closed-world. "
       "Atoms appearing here cannot appear in the -c option."),
    // END: Common arguments

    // BEGIN: Common inference arguments
  ARGS("exact", ARGS::Tog, aexactInfer,
      "(Embed in -infer argument) "
      "Run exact inference when all clauses are non-recursive ones."),

  ARGS("m", ARGS::Tog, amapPos,
       "(Embed in -infer argument) "
       "Run MAP inference and return only positive query atoms."),

  ARGS("a", ARGS::Tog, amapAll,
       "(Embed in -infer argument) "
       "Run MAP inference and show 0/1 results for all query atoms."),
  
  ARGS("ilp", ARGS::Tog, ailpInfer,
       "Run MPE inference using Integer Linear Programming "
       "for all query atoms"),

  ARGS("seed", ARGS::Opt, aSeed,
       "(Embed in -infer argument) "
       "[2350877] Seed used to initialize the randomizer in the inference "
       "algorithm. If not set, seed is initialized from a fixed random number."),

  ARGS("lazy", ARGS::Opt, aLazy,
       "(Embed in -infer argument) "
       "[false] Run lazy version of inference if this flag is set."),

  ARGS("lazyNoApprox", ARGS::Opt, aLazyNoApprox,
       "(Embed in -infer argument) "
       "[false] Lazy version of inference will not approximate by deactivating "
       "atoms to save memory. This flag is ignored if -lazy is not set."),

  ARGS("memLimit", ARGS::Opt, aMemLimit,
       "(Embed in -infer argument) "
       "[-1] Maximum limit in kbytes which should be used for inference. "
       "-1 means main memory available on system is used."),
    // END: Common inference arguments

    // BEGIN: MaxWalkSat args
  ARGS("mwsMaxSteps", ARGS::Opt, amwsMaxSteps,
       "(Embed in -infer argument) "
       "[100000] (MaxWalkSat) The max number of steps taken."),

  ARGS("tries", ARGS::Opt, amwsTries,
       "(Embed in -infer argument) "
       "[1] (MaxWalkSat) The max number of attempts taken to find a solution."),

  ARGS("targetWt", ARGS::Opt, amwsTargetWt,
       "(Embed in -infer argument) "
       "[the best possible] (MaxWalkSat) MaxWalkSat tries to find a solution "
       "with weight <= specified weight."),

  ARGS("hard", ARGS::Opt, amwsHard,
       "(Embed in -infer argument) "
       "[false] (MaxWalkSat) MaxWalkSat never breaks a hard clause in order to "
       "satisfy a soft one."),

  ARGS("heuristic", ARGS::Opt, amwsHeuristic,
       "(Embed in -infer argument) "
       "[2] (MaxWalkSat) Heuristic used in MaxWalkSat (0 = RANDOM, 1 = BEST, "
       "2 = TABU, 3 = SAMPLESAT)."),

  ARGS("tabuLength", ARGS::Opt, amwsTabuLength,
       "(Embed in -infer argument) "
       "[5] (MaxWalkSat) Minimum number of flips between flipping the same "
       "atom when using the tabu heuristic in MaxWalkSat." ),

  ARGS("lazyLowState", ARGS::Opt, amwsLazyLowState,
       "(Embed in -infer argument) "
       "[false] (MaxWalkSat) If false, the naive way of saving low states "
       "(each time a low state is found, the whole state is saved) is used; "
       "otherwise, a list of variables flipped since the last low state is "
       "kept and the low state is reconstructed. This can be much faster for "
       "very large data sets."),
    // END: MaxWalkSat args

    // BEGIN: ILP args
  ARGS("ilpLPRelax", ARGS::Tog, ailpLPRelaxation,
         "[false] If true, print out debugging information when running integer linear programming"),

  ARGS("ilpdebug", ARGS::Tog, ailpdebug,
       "[false] If true, print out debugging information when running integer linear programming"),

  ARGS("ilpSolver", ARGS::Opt, ailpSolver,
      "[1] "
      "ILP solver "
      "1: MOSKEK; 2: LPSOLVE;"),

  ARGS("ilpRounding", ARGS::Opt, ailpRoundingScheme,
     "[1] "
     "Rounding scheme "
     "1: SIMPLE; 2: F3; 3: F4; 4:ROUND_UP(default)"),

    // END: ILP args

  ARGS("exactdebug", ARGS::Tog, aexactdebug,
       "[false] If true, print out debugging information when running exact inference"),

  ARGS("lossAugmented", ARGS::Tog, alossAugmentedInfer,
       "[false] If true, perform loss augmented inference"),

    // BEGIN: Weight learning specific args
  ARGS("periodic", ARGS::Tog, aPeriodicMLNs,
       "Write out MLNs after 1, 2, 5, 10, 20, 50, etc. iterations"),

  ARGS("infer", ARGS::Opt, aInferStr,
       "Specified inference parameters when using discriminative learning. "
       "The arguments are to be encapsulated in \"\" and the syntax is "
       "identical to the infer command (run infer with no commands to see "
       "this). If not specified, 5 steps of MC-SAT with no burn-in is used."),

  ARGS("d", ARGS::Tog, discLearn, "Discriminative weight learning."),

  ARGS("g", ARGS::Tog, genLearn, "Generative weight learning."),

  ARGS("o", ARGS::Req, outMLNFile,
       "Output .mln file containing formulas with learned weights."),

  ARGS("t", ARGS::Req, dbFiles,
       "Comma-separated .db files containing the training database "
       "(of true/false ground atoms), including function definitions, "
       "e.g. ai.db,graphics.db,languages.db."),

  ARGS("ne", ARGS::Opt, nonEvidPredsStr,
       "First-order non-evidence predicates (comma-separated with no space),  "
       "e.g., cancer,smokes,friends. For discriminative learning, at least "
       "one non-evidence predicate must be specified. For generative learning, "
       "the specified predicates are included in the (weighted) pseudo-log-"
       "likelihood computation; if none are specified, all are included."),

  ARGS("noAddUnitClauses", ARGS::Tog, noAddUnitClauses,
       "If specified, unit clauses are not included in the .mln file; "
       "otherwise they are included."),

  ARGS("multipleDatabases", ARGS::Tog, multipleDatabases,
       "If specified, each .db file belongs to a separate database; "
       "otherwise all .db files belong to the same database."),

  ARGS("withEM", ARGS::Tog, withEM,
       "If set, EM is used to fill in missing truth values; "
       "otherwise missing truth values are set to false."),

   ARGS("dC", ARGS::Opt, C,
          "[1] (For cutting plane method only.) "
          "Regularization parameter."),

  ARGS("dEpsilon", ARGS::Opt, epsilon,
          "[1] (For cutting plane method only.) "
          "Stopping parameter."),

  ARGS("dLoss", ARGS::Opt, lossFunction,
        "[1] (For cutting plane method only.) "
        "Loss function, "
		"1: HAMMING; 2: F1"),

  ARGS("dLossScale", ARGS::Opt, lossScale,
		"[1] (For cutting plane method only.) "
		"The loss value will be multiplied by this number, "
		"1(default)"),

  ARGS("dNonMarginRescaling", ARGS::Tog, nonMarginRescaling,
      "[false] (For max margin learning only) "
      "If set, don't scale the margin by the loss."),

  ARGS("dNumIter", ARGS::Opt, numIter,
       "[1000] (For discriminative learning only.) "
       "Number of iterations to run discriminative learning method."),

  ARGS("dNumMinIter", ARGS::Opt, numMinIter,
      "[1] (For discriminative learning only.) "
      "Number of minimum iterations to run discriminative learning method."),

  ARGS("dMaxSec", ARGS::Opt, maxSec,
       "[-1] Maximum number of seconds to spend learning"),

  ARGS("dMaxMin", ARGS::Opt, maxMin,
       "[-1] Maximum number of minutes to spend learning"),

  ARGS("dMaxHour", ARGS::Opt, maxHour,
       "[-1] Maximum number of hours to spend learning"),

  ARGS("queryEvidence", ARGS::Tog, isQueryEvidence,
       "[false] If this flag is set, then all the groundings of query preds not "
       "in db are assumed false evidence."),

  ARGS("useL1", ARGS::Tog, useL1,
        "[flase] "
        "Use L1 regularization instead of L2."),

  ARGS("debug", ARGS::Tog, debug, "Output debugging information."),

  ARGS("trainFileNamesInOneFile", ARGS::Tog, trainFileNamesInOneFile,
	 "The file specified in the -t option contains a list of db files"),

  ARGS("ignoreUnknownQueryAtom", ARGS::Tog, ignoreUnknownQueryAtom,
	 "Don't count the unkown query atom in inference"),

 ARGS("printLearnedWeightPerIteration", ARGS::Tog, printLearnedWeightPerIter,
	 "Print the learned weights for each iteration"),

 ARGS("nonRecursive", ARGS::Tog, nonRecursive,
 	 "[false]"
 	 "Set to true when all the clauses are non-recursive"),
	 
  ARGS()
};

//bool extractPredNames(...) defined in infer.h

int main(int argc, char* argv[])
{
  ARGS::parse(argc,argv,&cout);

  if (!discLearn && !genLearn)
  {
      // If nothing specified, then use disc. learning
    discLearn = true;

    //cout << "must specify either -d or -g "
    //     <<"(discriminative or generative learning) " << endl;
    //return -1;
  }

  Timer timer;
  double startSec = timer.time();
  double begSec;

  if (priorStdDev < 0)
  {
    if (discLearn)
    {
      cout << "priorStdDev set to (discriminative learning's) default of "
           << DISC_DEFAULT_STD_DEV << endl;
      priorStdDev = DISC_DEFAULT_STD_DEV;
    }
    else
    {
      cout << "priorStdDev set to (generative learning's) default of "
           << GEN_DEFAULT_STD_DEV << endl;
      priorStdDev = GEN_DEFAULT_STD_DEV;
    }
  }


  ///////////////////////// check and extract the parameters //////////////////
  if (discLearn && nonEvidPredsStr == NULL)
  {
    cout << "ERROR: you must specify non-evidence predicates for "
         << "discriminative learning" << endl;
    return -1;
  }

  if (maxIter <= 0)  { cout << "maxIter must be > 0" << endl; return -1; }
  if (convThresh <= 0 || convThresh > 1)
  { cout << "convThresh must be > 0 and <= 1" << endl; return -1;  }
  if (priorStdDev <= 0) { cout << "priorStdDev must be > 0" << endl; return -1;}

  if (amwsMaxSteps <= 0)
  { cout << "ERROR: mwsMaxSteps must be positive" << endl; return -1; }

    // If max. subsequent steps not specified, use amwsMaxSteps
  if (amwsMaxSubsequentSteps <= 0) amwsMaxSubsequentSteps = amwsMaxSteps;

  if (amwsTries <= 0)
  { cout << "ERROR: tries must be positive" << endl; return -1; }

  if (aMemLimit <= 0 && aMemLimit != -1)
  { cout << "ERROR: limit must be positive (or -1)" << endl; return -1; }

  if (!discLearn && aLazy)
  {
    cout << "ERROR: lazy can only be used with discriminative learning"
         << endl;
    return -1;
  }

  ofstream out(outMLNFile);
  if (!out.good())
  {
    cout << "ERROR: unable to open " << outMLNFile << endl;
    return -1;
  }

    // Parse the inference parameters, if given
  if (discLearn)
  {
    if (!aInferStr)
    {
        // Set defaults of inference inside disc. weight learning:
        // MC-SAT with no burn-in, 5 steps
      amcsatInfer = true;
    }
      // If inference method given, we need to parse the parameters
    else
    {
      int inferArgc = 0;
      char **inferArgv = new char*[200];
      for (int i = 0; i < 200; i++)
      {
        inferArgv[i] = new char[500];
      }

        // Have to add program name (which is not used) to start of string
      string inferString = "infer ";
      inferString.append(aInferStr);
      extractArgs(inferString.c_str(), inferArgc, inferArgv);
      cout << "extractArgs " << inferArgc << endl;
      for (int i = 0; i < inferArgc; i++)
      {
        cout << i << ": " << inferArgv[i] << endl;
      }

      ARGS::parseFromCommandLine(inferArgc, inferArgv);

        // Delete memory allocated for args
      for (int i = 0; i < 200; i++)
      {
        delete[] inferArgv[i];
      }
      delete[] inferArgv;
    }

     if (!aexactInfer && !ailpInfer && !amapPos && !amapAll)
      {
          // If nothing specified, use ILP inference
        ailpInfer = true;
      }
  }


  //the second .mln file to the last one in ainMLNFiles _may_ be used
  //to hold constants, so they are held in constFilesArr. They will be
  //included into the first .mln file.

    //extract .mln and .db, file names
  Array<string> constFilesArr;
  Array<string> dbFilesArr;
  extractFileNames(ainMLNFiles, constFilesArr);
  assert(constFilesArr.size() >= 1);
  string inMLNFile = constFilesArr[0];
  constFilesArr.removeItem(0);
  if (trainFileNamesInOneFile) {
	  // Open the file
	  ifstream in(dbFiles);
	  string buffer;
	  while(getline(in, buffer)) {
		  dbFilesArr.append(buffer);
	  }
	  in.close();
  }
  else  {
	  extractFileNames(dbFiles, dbFilesArr);
  }

  if (dbFilesArr.size() <= 0)
  {cout<<"ERROR: must specify training data with -t option."<<endl; return -1;}

    // if multiple databases, check the number of .db/.func files
  if (multipleDatabases)
  {
      //if # .mln files containing constants/.func files and .db files are diff
    if ((constFilesArr.size() > 0 && constFilesArr.size() != dbFilesArr.size()))
    {
      cout << "ERROR: when there are multiple databases, if .mln files "
           << "containing constants are specified, there must "
           << "be the same number of them as .db files" << endl;
      return -1;
    }
  }

  StringHashArray nonEvidPredNames;
  if (nonEvidPredsStr)
  {
    if (!extractPredNames(nonEvidPredsStr, NULL, nonEvidPredNames))
    {
      cout << "ERROR: failed to extract non-evidence predicate names." << endl;
      return -1;
    }
  }

  StringHashArray owPredNames;
  StringHashArray cwPredNames;

  ////////////////////////// create domains and mlns //////////////////////////

  cout << "Parsing MLN and creating domains..." << endl;
  StringHashArray* nePredNames = (discLearn) ? &nonEvidPredNames : NULL;
  Array<Domain*> domains;
  Array<MLN*> mlns;
  begSec = timer.time();
  bool allPredsExceptQueriesAreCW = true;
  if (discLearn)
  {
      //extract names of open-world evidence predicates
    if (aOpenWorldPredsStr)
    {
      if (!extractPredNames(string(aOpenWorldPredsStr), NULL, owPredNames))
        return -1;
      assert(owPredNames.size() > 0);
    }

      //extract names of closed-world non-evidence predicates
    if (aClosedWorldPredsStr)
    {
      if (!extractPredNames(string(aClosedWorldPredsStr), NULL, cwPredNames))
        return -1;
      assert(cwPredNames.size() > 0);
      if (!checkQueryPredsNotInClosedWorldPreds(nonEvidPredNames, cwPredNames))
        return -1;
    }

    //allPredsExceptQueriesAreCW = owPredNames.empty();
    allPredsExceptQueriesAreCW = false;
  }
    // Parse as if lazy inference is set to true to set evidence atoms in DB
    // If lazy is not used, this is removed from DB
  createDomainsAndMLNs(domains, mlns, multipleDatabases, inMLNFile,
                       constFilesArr, dbFilesArr, nePredNames,
                       !noAddUnitClauses, priorMean, true,
                       allPredsExceptQueriesAreCW, &owPredNames, &cwPredNames);
  cout << "Parsing MLN and creating domains took ";
  Timer::printTime(cout, timer.time() - begSec); cout << endl;

  /*
  cout << "Clause prior means:" << endl;
  cout << "_________________________________" << endl;
  mlns[0]->printClausePriorMeans(cout, domains[0]);
  cout << "_________________________________" << endl;
  cout << endl;

  cout << "Formula prior means:" << endl;
  cout << "_________________________________" << endl;
  mlns[0]->printFormulaPriorMeans(cout);
  cout << "_________________________________" << endl;
  cout << endl;
  */

  //////////////////// set the prior means & standard deviations //////////////

    //we need an index translator if clauses do not line up across multiple DBs
  IndexTranslator* indexTrans
    = (IndexTranslator::needIndexTranslator(mlns, domains)) ?
       new IndexTranslator(&mlns, &domains) : NULL;

  if (indexTrans) {
	cout << endl << "The clauses do not line up across multiple DBs --> need an index translator" << endl;
    cout << "the weights of clauses in the CNFs of existential"
         << " formulas will be tied" << endl;
  }

  Array<double> priorMeans, priorStdDevs;
  if (!noPrior)
  {
    if (indexTrans)
    {
      indexTrans->setPriorMeans(priorMeans);
      priorStdDevs.growToSize(priorMeans.size());
      for (int i = 0; i < priorMeans.size(); i++)
        priorStdDevs[i] = priorStdDev;
    }
    else
    {
      const ClauseHashArray* clauses = mlns[0]->getClauses();
      int numClauses = clauses->size();
      for (int i = 0; i < numClauses; i++)
      {
        priorMeans.append((*clauses)[i]->getWt());
        priorStdDevs.append(priorStdDev);
      }
    }
  }
  
  int numClausesFormulas;
  if (indexTrans)
      numClausesFormulas = indexTrans->getNumClausesAndExistFormulas();
  else
      numClausesFormulas = mlns[0]->getClauses()->size();


  //////////////////////  discriminative/generative learning /////////////////
  Array<double> wts;

    // Discriminative learning
  if (discLearn)
  {
    wts.growToSize(numClausesFormulas + 1);
    double* wwts = (double*) wts.getItems();
    wwts++;
      // Non-evid preds as a string
    string nePredsStr = nonEvidPredsStr;

      // Set SampleSat parameters
    SampleSatParams* ssparams = new SampleSatParams;
    ssparams->lateSa = assLateSa;
    ssparams->saRatio = assSaRatio;
    ssparams->saTemp = assSaTemp;

      // Set MaxWalksat parameters
    MaxWalksatParams* mwsparams = NULL;
    mwsparams = new MaxWalksatParams;
    mwsparams->ssParams = ssparams;
    mwsparams->maxSteps = amwsMaxSteps;
    mwsparams->maxTries = amwsTries;
    mwsparams->targetCost = amwsTargetWt;
    mwsparams->hard = amwsHard;
      // numSolutions only applies when used in SampleSat.
      // When just MWS, this is set to 1
    mwsparams->numSolutions = amwsNumSolutions;
    mwsparams->heuristic = amwsHeuristic;
    mwsparams->tabuLength = amwsTabuLength;
    mwsparams->lazyLowState = amwsLazyLowState;
    
    // Set ILP parameters
    ILPParams* ilpparams = new ILPParams;    
    ilpparams->debug                  = ailpdebug;
    ilpparams->lossAugmentedInfer     = alossAugmentedInfer;
    ilpparams->LPRelaxation           = ailpLPRelaxation;
    ilpparams->solver				  = ailpSolver;
    ilpparams->lossFunction			  = lossFunction;
    ilpparams->lossScale			  = lossScale;
    ilpparams->roundingScheme	      = ailpRoundingScheme;

    // Set Exact parameters
    ExactParams* exactparams = new ExactParams;
    exactparams->debug               = aexactdebug;
    exactparams->lossAugmentedInfer   = alossAugmentedInfer;
    exactparams->lossFunction			  = lossFunction;
    exactparams->lossScale   = lossScale;


    Array<VariableState*> states;
    Array<Inference*> inferences;

    states.growToSize(domains.size());
    inferences.growToSize(domains.size());

      // Build the state for inference in each domain
    Array<int> allPredGndingsAreNonEvid;    
    Array<Predicate*> ppreds;

    for (int i = 0; i < domains.size(); i++)
    {
      cout << endl << "processing domain " << i << "..." << endl;
      Domain* domain = domains[i];
      MLN* mln = mlns[i];
      
        // Remove evidence atoms structure from DBs
      if (!aLazy)
        domains[i]->getDB()->setLazyFlag(false);

        // Unknown non-ev. preds
      GroundPredicateHashArray* unePreds = NULL;

        // Known non-ev. preds
      GroundPredicateHashArray* knePreds = NULL;
      Array<TruthValue>* knePredValues = NULL;

        // Need to set some dummy weight
      for (int j = 0; j < mln->getNumClauses(); j++)
        ((Clause*) mln->getClause(j))->setWt(1);

	  // Make open-world evidence preds into non-evidence
      if (!allPredsExceptQueriesAreCW)
      {
        for (int i = 0; i < owPredNames.size(); i++)
        {
          nePredsStr.append(",");
          nePredsStr.append(owPredNames[i]);
          nonEvidPredNames.append(owPredNames[i]);
        }
      }

      Array<Predicate*> gpreds;
      Array<TruthValue> gpredValues;
        // Eager version: Build query preds from command line and set known
        // non-evidence to unknown for building the states
      if (!aLazy)
      {
        unePreds = new GroundPredicateHashArray;
        knePreds = new GroundPredicateHashArray;
        knePredValues = new Array<TruthValue>;

        allPredGndingsAreNonEvid.growToSize(domain->getNumPredicates(), false);
          //defined in infer.h
        createComLineQueryPreds(nePredsStr, domain, domain->getDB(),
                                unePreds, knePreds,
                                &allPredGndingsAreNonEvid,NULL);

        cout << "Number of unknown non-evidence grounding predicates = " << unePreds->size() << endl;
        cout << "Number of known non-evidence grounding predicates = " << knePreds->size() << endl;

          // Pred values not set to unknown in DB: unePreds contains
          // unknown, knePreds contains known non-evidence

          // Set known NE to unknown for building state
          // and set blockEvidence to false if this was the true evidence
        knePredValues->growToSize(knePreds->size(), FALSE);
        for (int predno = 0; predno < knePreds->size(); predno++)
        {
            // If this was the true evidence in block, then erase this info
          int blockIdx = domain->getBlock((*knePreds)[predno]);
          if (blockIdx > -1 &&
              domain->getDB()->getValue((*knePreds)[predno]) == TRUE)
          {
            domain->setBlockEvidence(blockIdx, false);
          }
            // Set value to unknown
          (*knePredValues)[predno] =
            domain->getDB()->setValue((*knePreds)[predno], UNKNOWN);
        }

          // If first order query pred groundings are allowed to be evidence
          // - we assume all the predicates not in db to be false
          // evidence - need a better way to code this.
        if (isQueryEvidence)
        {
            // Set unknown NE to false
          for (int predno = 0; predno < unePreds->size(); predno++)
          {
            domain->getDB()->setValue((*unePreds)[predno], FALSE);
            delete (*unePreds)[predno];
          }
          unePreds->clear();
        }
      }
      else
      {
        Array<Predicate*> ppreds;

        domain->getDB()->setPerformingInference(false);

        gpreds.clear();
        gpredValues.clear();
        for (int predno = 0; predno < nonEvidPredNames.size(); predno++)
        {
          ppreds.clear();
          int predid = domain->getPredicateId(nonEvidPredNames[predno].c_str());
          Predicate::createAllGroundings(predid, domain, ppreds);
          gpreds.append(ppreds);
        }
        //domain->getDB()->alterTruthValue(&gpreds, UNKNOWN, FALSE, &gpredValues);
        domain->getDB()->setValuesToUnknown(&gpreds, &gpredValues);
      }

        // Create state for inferred counts using unknown and known (set to
        // unknown in the DB) non-evidence preds
      cout << "constructing state for domain " << i << "..." << endl;
      bool markHardGndClauses = false;
      bool trackParentClauseWts = true;

      VariableState*& state = states[i];
      state = new VariableState(unePreds, knePreds, knePredValues,
                                &allPredGndingsAreNonEvid, markHardGndClauses,
                                trackParentClauseWts, mln, domain, aLazy);
      /*
      if (debug){
    	  cout << "Number of ground clauses: " << state->getNumClauses() << endl;
    	  cout << "List of ground clauses: " << endl;
    	  for (int var = 0; var < state->getNumClauses(); ++var) {
    		  GroundClause* gndClause = state->getGndClause(var);
    		  gndClause->printWithWtAndStrVar(cout,domain,state->getGndPredHashArrayPtr());
    		  cout << endl;
		  }

      }
      */

      Inference*& inference = inferences[i];
      bool trackClauseTrueCnts = true;
        // Different inference algorithms
      if (aexactInfer)
      {
    	  inference = new ExactInference(state, aSeed, trackClauseTrueCnts, exactparams);
      }
      else if (ailpInfer)
	  {
	      inference = new ILPInference(state, aSeed, trackClauseTrueCnts, ilpparams);
	  }
      else if (amapPos || amapAll)
      { // MaxWalkSat
          // When standalone MWS, numSolutions is always 1
          // (maybe there is a better way to do this?)
        //mwsparams->numSolutions = 1;
        inference = new MaxWalkSat(state, aSeed, trackClauseTrueCnts,
                                   mwsparams);
    	  //inference = new LossAugmentedExactInference(state,aSeed,trackClauseTrueCnts,loss,maxMargin);
      }      

      if (!aLazy)
      {
          // Change known NE to original values
        domain->getDB()->setValuesToGivenValues(knePreds, knePredValues);
          // Set unknown NE to false for weight initialization. This seems to
          // give poor results when using EM. We need to leave these
          // as unknown and do the counts accordingly
        if (!ignoreUnknownQueryAtom) {
	        for (int predno = 0; predno < unePreds->size(); predno++)
	        {
	          domain->getDB()->setValue((*unePreds)[predno], FALSE);
	        }
        }
      }
      else
      {
        domain->getDB()->setValuesToGivenValues(&gpreds, &gpredValues);

        //cout << "the ground predicates are :" << endl;
        for (int predno = 0; predno < gpreds.size(); predno++)
        {
          //gpreds[predno]->printWithStrVar(cout, domain);
          //cout << endl;
          delete gpreds[predno];
        }

        domain->getDB()->setPerformingInference(true);
      }
    }
    cout << endl << "done constructing variable states" << endl << endl;

    MaxMarginLearner mml(inferences, nonEvidPredNames, indexTrans, aLazy, withEM, debug);

    //mml.setMeansStdDevs(-1, NULL, NULL);

    cout << endl << "learning discriminative weights... " << endl;
    begSec = timer.time();
    double maxTime = maxSec + 60*maxMin + 3600*maxHour;
	if (useL1)
    	mml.learnWeightsCPL1(wwts, wts.size()-1, numIter, numMinIter, maxTime, C, epsilon, lossFunction, lossScale, initWithLogOdds, nonMarginRescaling,ignoreUnknownQueryAtom,printLearnedWeightPerIter,nonRecursive);
    else
    	mml.learnWeightsCP(wwts, wts.size()-1, numIter, numMinIter, maxTime, C, epsilon, lossFunction, lossScale, initWithLogOdds, nonMarginRescaling,ignoreUnknownQueryAtom,printLearnedWeightPerIter,nonRecursive);
    
    
    cout << "Time Taken for learning = ";
    Timer::printTime(cout, (timer.time() - begSec)); cout << endl;
    cout << endl << endl << "Done learning discriminative weights. "<< endl;

    if (mwsparams) delete mwsparams;    
    for (int i = 0; i < inferences.size(); i++)  delete inferences[i];
    for (int i = 0; i < states.size(); i++)  delete states[i];
  }
  
  //////////////////////////// output results ////////////////////////////////
  cout << "Assigning learned weights and writing out the final MLN ... " << endl;
  if (indexTrans) assignWtsAndOutputMLN(out, mlns, domains, wts, indexTrans);
  else            assignWtsAndOutputMLN(out, mlns, domains, wts);

  out.close();

  cout << "cleaning up ... " << endl;
  /////////////////////////////// clean up ///////////////////////////////////
  cout << "deleting domains ..." << endl;
  deleteDomains(domains);

  cout << "deleting share data structures ..." << endl;
  for (int i = 0; i < mlns.size(); i++)
  {
    if (DOMAINS_SHARE_DATA_STRUCT && i > 0)
    {
      mlns[i]->setClauses(NULL);
      mlns[i]->setMLNClauseInfos(NULL);
      mlns[i]->setPredIdToClausesMap(NULL);
      mlns[i]->setFormulaAndClausesArray(NULL);
      mlns[i]->setExternalClause(NULL);
    }
    delete mlns[i];
  }

  PowerSet::deletePowerSet();
  if (indexTrans) delete indexTrans;

  cout << "Total time = ";
  Timer::printTime(cout, timer.time() - startSec); cout << endl;
}
