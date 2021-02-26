#ifndef UTEXACTINFER_H_
#define UTEXACTINFER_H_

#include "inference.h"

/**
 * This struct holds parameters for the exact inference algorithm.
 */
struct ExactParams
{
  bool debug;
  bool lossAugmentedInfer;
  int lossFunction;
  double lossScale;
};

class ExactInference : public Inference
{
 public:

  /**
   *
   */
  ExactInference(VariableState* state, long int seed,
                  const bool& trackClauseTrueCnts, ExactParams* exactParams)
    : Inference(state, seed, trackClauseTrueCnts) {

	  exactdebug_ = exactParams->debug;
	  lossAugmentedInfer_ = exactParams->lossAugmentedInfer;
	  lossScale_ = exactParams->lossScale;
  }

  ~ExactInference() {}

  /**
   * There is nothing to initialize in exact inference.
   */
  void init() {}

  void reinit() {}

  void printNetwork(ostream& out) {}
  void printTruePredsH(ostream& out) {}
  double getProbabilityH(GroundPredicate* const& gndPred) {
	  return 0;
  }
  
  void infer()
  {
    cout << "Entering ExactInference::infer" << endl;
    if (lossAugmentedInfer_) cout << "Running loss augmented inference ... " << endl;

    const Domain* domain = state_->getDomain();
	// get query predicate id
    const GroundPredicateHashArray* knePreds = state_->getKnePreds();
    const Array<TruthValue>* knePredValues = state_->getKnePredValues();
    const GroundPredicateHashArray* unePreds = state_->getUnePreds();
    int numOfQueryAtoms = state_->getNumAtoms();
    int numOfKnownPreds = 0;
    int numOfUnknownPreds = 0;

    if (knePreds != NULL){
    	numOfKnownPreds = knePreds->size();
    }
    if (unePreds != NULL) {
    	numOfUnknownPreds = unePreds->size();
    }

    if (exactdebug_){
    	cout << "Number of query atoms: " << numOfQueryAtoms << endl;
    }

    for (int i = 0; i < numOfKnownPreds; ++i) {
    	GroundPredicate* gndPred = (*knePreds)[i];
    	// reset the weight
    	gndPred->setWtWhenFalse(0);
    	gndPred->setWtWhenTrue(0);

    	if (exactdebug_) {
    		cout << "Predicate " << (i+1) << ": ";
    		gndPred->print(cout,domain);
    		cout << endl;
    	}

    	if (lossAugmentedInfer_){
    		if ((*knePredValues)[i] == TRUE) {
    			gndPred->addWtWhenFalse(1*lossScale_);
	    	}
	    	else {
	    		gndPred->addWtWhenTrue(1*lossScale_);
	    	}
    	}
    }

    for (int i = 0; i < numOfUnknownPreds; ++i) {
        	GroundPredicate* gndPred = (*unePreds)[i];
        	// reset the weight
        	gndPred->setWtWhenFalse(0);
        	gndPred->setWtWhenTrue(0);

        	if (exactdebug_) {
        		cout << "Predicate " << (i+1) << ": ";
        		gndPred->print(cout,domain);
        		cout << endl;
        	}

        	if (lossAugmentedInfer_){
        		gndPred->addWtWhenTrue(1*lossScale_);
        	}
    }

    for (int i = 0; i < numOfQueryAtoms; ++i) {
    	GroundPredicate* gndPred = state_->getGndPred(i);
    	//int idx = state_->getGndPredIndex(gndPred);

    	const Array<GroundClause*>* posGndClauses = gndPred->getPosGndClauses();
    	if (!posGndClauses->empty()) {
    		GroundClause* gndClause = (*posGndClauses)[0];
    		if (exactdebug_) {
				cout << "Positive ground clause: ";
				gndClause->print(cout,domain,state_->getGndPredHashArrayPtr());
				cout << endl;
			}
			gndPred->addWtWhenTrue(gndClause->getWt());
    	}

    	const Array<GroundClause*>* negGndClauses = gndPred->getNegGndClauses();
    	if (!negGndClauses->empty()) {
    		GroundClause* gndClause = (*negGndClauses)[0];
    		if (exactdebug_) {
				cout << "Negative ground clause: ";
				gndClause->print(cout,domain,state_->getGndPredHashArrayPtr());
				cout << endl;
			}
			gndPred->addWtWhenFalse(gndClause->getWt());
    	}

    	if (exactdebug_) {
    		cout << "Weight when true: " << gndPred->getWtWhenTrue() << endl;
    		cout << "Weight when false: " << gndPred->getWtWhenFalse() << endl;
    	}

    	if (gndPred->getWtWhenTrue() > gndPred->getWtWhenFalse()) {
    		if (exactdebug_)
    			cout << "Infered value: TRUE" << endl;
    		state_->setValueOfAtom(i+1,true,false,-1);
    		//domain->getDB()->setValue(gndPred,TRUE);
    		gndPred->setTruthValue(true);
    		//cout << "Reading back truth value: " << gndPred->getTruthValue() << endl;
    	}
    	else {
    		if (exactdebug_)
    			cout << "Infered value: FALSE" << endl;
    		state_->setValueOfAtom(i+1,false,false,-1);
    		//domain->getDB()->setValue(gndPred,FALSE);
    		gndPred->setTruthValue(false);
    		//cout << "Reading back truth value: " << gndPred->getTruthValue() << endl;
    	}
	}

    state_->saveLowState();

    if (exactdebug_) cout << "Leaving ExactInference::infer" << endl;
  }

  /**
   * Prints the best state found.
   */
  void printProbabilities(ostream& out)
  {
    for (int i = 0; i < state_->getNumAtoms(); i++)
    {
      state_->printGndPred(i, out);
      out << " " << state_->getValueOfLowAtom(i + 1) << endl;
    }
  }

  /**
   * Puts the predicates whose truth value has changed with respect to the
   * reference vector oldProbs in string form and the corresponding
   * probabilities of each predicate (1 or 0) in two vectors.
   *
   * @param changedPreds Predicates whose truth values have changed are put
   * here.
   * @param probs The probabilities corresponding to the predicates in
   * nonZeroPreds are put here (the number 1 or 0).
   * @param oldProbs Reference truth values for checking for changes.
   * @param probDelta This parameter is ignored for MAP inference (either the
   * truth value has changed or it hasn't).
   */
  void getChangedPreds(vector<string>& changedPreds, vector<float>& probs,
                       vector<float>& oldProbs, const float& probDelta)
  {
    changedPreds.clear();
    probs.clear();
    int numAtoms = state_->getNumAtoms();
      // Atoms may have been added to the state, previous tv was 0
    oldProbs.resize(numAtoms, 0);
    for (int i = 0; i < numAtoms; i++)
    {
      int tv = state_->getValueOfLowAtom(i + 1);
      if (tv != oldProbs[i])
      {
          // Truth value has changed: Store new value in oldProbs and add to
          // two return vectors
        oldProbs[i] = tv;
        ostringstream oss(ostringstream::out);
        state_->printGndPred(i, oss);
        changedPreds.push_back(oss.str());
        probs.push_back(tv);
      }
    }
  }

  /**
   * Gets the truth value of a ground predicate in the best state found.
   */
  double getProbability(GroundPredicate* const& gndPred)
  {
	/*
    int idx = state_->getGndPredIndex(gndPred);
    int truthValue = 0;
    if (idx >= 0) truthValue = state_->getValueOfLowAtom(idx + 1);
    return truthValue;*/
	return gndPred->getProbability();
  }

  /**
   * Prints the predicates set to true in the best state to a stream.
   */
  void printTruePreds(ostream& out)
  {
    for (int i = 0; i < state_->getNumAtoms(); i++)
    {
      if (state_->getValueOfLowAtom(i + 1))
      {
        state_->printGndPred(i, out);
        out << endl;
      }
    }
  }

 private:
 double * probs_;
 bool lossAugmentedInfer_;
 bool exactdebug_;
 double lossScale_;

};


#endif /*UTEXACTINFER_H_*/
