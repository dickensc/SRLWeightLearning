#ifndef UTILPINFER_H_
#define UTILPINFER_H_

#include "lp_lib.h"
#include "mosek.h" // Include the MOSEK definition file.
#include <math.h>
#include <ctime>    // For time()
#include "inference.h"
#include "array.h"

static void MSKAPI printstr(void *handle, char str[])
{
	printf("%s",str);
} /* printstr */

/**
 * This struct holds parameters for the integer linear programming inference algorithm.
 */
struct ILPParams
{  
  int solver;
  int roundingScheme;
  int lossFunction;
  double lossScale;

  bool debug;
  bool lossAugmentedInfer;
  bool LPRelaxation;
};

class ILPInference : public Inference
{
 public:

  /**
   *
   */
  ILPInference(VariableState* state, long int seed,
                  const bool& trackClauseTrueCnts, ILPParams* ilpParams)
    : Inference(state, seed, trackClauseTrueCnts)
  {
	ilpdebug_ = ilpParams->debug;
	lossAugmentedInfer_ = ilpParams->lossAugmentedInfer;
	LPRelaxation_ = ilpParams->LPRelaxation;
	solver_ = ilpParams->solver;
	roundingScheme_ = ilpParams->roundingScheme;
	lossFunction_ = ilpParams->lossFunction;
	lossScale_ = ilpParams->lossScale;
  }

  ~ILPInference() {}

  /**
   * There is nothing to initialize in ilp inference.
   */
  void init() {}

  void reinit() {}
  
  void printNetwork(ostream& out) {}
  void printTruePredsH(ostream& out) {}
  double getProbabilityH(GroundPredicate* const& gndPred) {
	  return 0;
  }

  void infer() {
	  cout << "Entering ILPInference::infer" << endl;
	  if (lossAugmentedInfer_) cout << "Running loss augmented inference ... " << endl;
	  switch (solver_) {
	  	case MOSEK:
	  		inferMosek();
	  		break;
	  	case LPSOLVE:
	  		inferLPSolve();
	  		break;
	  	default:
	  		inferMosek();
	  		break;
	  }
  }

  void inferLPSolve()
    {
	  cout << "ILP solver: lpsove" << endl;
  	  // get query predicate id
      const Domain* domain = state_->getDomain();
      const GroundPredicateHashArray* knePreds = state_->getKnePreds();
      const GroundPredicateHashArray* unePreds = state_->getUnePreds();
      const GroundPredicateHashArray* gndPredHashArray = state_->getGndPredHashArrayPtr();
      const Array<TruthValue>* knePredValues = state_->getKnePredValues();
      int numOfKnownPreds = 0;
      int numOfUnknownPreds = 0;
      int numOfGndClauses = state_->getNumClauses();
      int numOfGndPredicates = state_->getNumAtoms();

      if (knePreds != NULL){
      	numOfKnownPreds = knePreds->size();
      }
      if (unePreds != NULL) {
      	numOfUnknownPreds = unePreds->size();
      }

      if (ilpdebug_){
      	cout << "Number of grounding predicates: " << numOfGndPredicates << endl;
      	cout << "Number of grounding clauses: " << numOfGndClauses << endl;
      }

      // Setup the LP solver
      int MAXNUMVAR = numOfGndClauses + numOfGndPredicates;
      int MAXNUMCON = numOfGndClauses*2;
      //double xx[MAXNUMVAR];
      int ret = 1;
      int numVar = numOfGndPredicates;
      int numCon = 0;
      lprec *lp;

      // Create the model.
      lp = make_lp(0, numOfGndPredicates);

      if(lp == NULL) {
    	 cout << "Unable to create new LP model" << endl ;
    	 return;
      }

      set_verbose(lp, DETAILED);

      if (ret == 1)
      {
    	  // Put variable bound and constraints
  		  for(int j=1; j <= numOfGndPredicates; ++j) {
  			  ret = set_bounds(lp,j,0,1);
  			  if (!LPRelaxation_)
  				  ret = set_int(lp,j,TRUE);
  		  }

    	  double coff[numOfGndPredicates];
    	  for (int i = 0; i < numOfGndPredicates; ++i) {
  			coff[i] = 0;
  	  }

	  if (ilpdebug_) {
		  cout << "Process each ground clause ... " << endl;
	  }

	  for (int clauseInd = 0; clauseInd < numOfGndClauses; clauseInd++) {
		  GroundClause* gndClause = state_->getGndClause(clauseInd);
		  gndClause->setSatisfied(false);
		  if (ilpdebug_) {
			  gndClause->printWithWtAndStrVar(cout,state_->getDomain(),gndPredHashArray);
			  cout << endl;
		  }

		  double wt = gndClause->getWt();
		  double hardWt = state_->getHardWt();
		  if (hardWt > 1000000) {
			  hardWt = 1000000;
		  }
		  if (wt >= hardWt) {
  			  if (ilpdebug_) {
  				cout << "This is a hard clause, adding a constraint for it..." << endl;
	  		  }

  			  // Append a new constraint
		  	  double lowerBound = 1; // guarantee that the solution satifies this hard clauses
		  	  int numOfGndPreds = gndClause->getNumGroundPredicates();

		  	  // Put new values in the A matrix
		  	  if (ret == 1) {
		  		  double sparserow[numOfGndPreds];
		  		  int colno[numOfGndPreds];

		  		  for (int predId = 0; predId < numOfGndPreds; ++predId) {
		  			  GroundPredicate* gndPred = gndClause->getGroundPredicate(predId,gndPredHashArray);
		  			  int predIndex = state_->getGndPredIndex(gndPred);

		  			  if (gndClause->getGroundPredicateSense(predId)) {
		  				  colno[predId] = predIndex+1;
		  				  sparserow[predId] = 1.0;
		  			  }
		  			  else {
		  				  colno[predId] = predIndex+1;
		  				  sparserow[predId] = -1.0;
		  				  lowerBound -= 1;
		  			  }
				  }

		  		  // put the coefficient of the auxiliary variable at the end position of this vector
		  		  colno[numOfGndPreds] = numVar;
		  		  sparserow[numOfGndPreds] = -1;

		  		  ret = add_constraintex(lp, numOfGndPreds, sparserow, colno, GE, lowerBound);
		  		  numCon++;
		  	  }
		  	  continue;
  		  }
		  if (wt) {

  		  	  int numOfGndPreds = gndClause->getNumGroundPredicates();

  	  		  if (numOfGndPreds == 1){
  	  			  // It's unit clause, we don't need to have an auxiliary variable for this clause
  	  			  GroundPredicate* gndPred = gndClause->getGroundPredicate(0,gndPredHashArray);
  	  			  int predIndex = state_->getGndPredIndex(gndPred);

  	  			  if (ilpdebug_) {
  	  				//cout << "predIndex: " << predIndex << endl;
  	  				//cout << "predSense: " << gndClause->getGroundPredicateSense(0) << endl;
  	  			  }

  	  			  if (gndClause->getGroundPredicateSense(0))
  	  				  coff[predIndex] = wt;
  	  			  else
  	  				  coff[predIndex] = -wt;
  	  		  }
  	  		  else {

  	  			  if (ilpdebug_) {
		  			  cout << "Adding a new variable for this clause ... " << endl;
		  		  }

  	  			  numVar++;
  	  			  if (ret == 1)
  	  				ret = add_columnex(lp,0, NULL, NULL);

  			  	  // Put variable bound
  				  if (ret == 1) {
  					  if (ilpdebug_) {
  						  cout << "Setting bound for new variable ... " << endl;
  					  }
  					  ret = set_bounds(lp,numVar-1,0,1);  					  
  					  if (!LPRelaxation_)
  					  	ret = set_int(lp,numVar-1,TRUE);
  				  }
  				  

  	  			  if (wt > 0) {
  	  				  // Clause with positive weight
  	  				  // In this case, we only need one constraint

  	  				  // Add the coefficient of this variable to the objective function
  				  	  if (ret == 1)
  				  		  ret = set_obj(lp,numVar,wt);

  				  	  // Append a new constraint
  				  	  if (ilpdebug_) {
  			  			  cout << "Adding the constraint for this positive clause ... " << endl;
  			  		  }

  				  	  double lowerBound = 0;

  				  	  // Put new values in the A matrix
  				  	  if (ret == 1) {
  				  		  double sparserow[numOfGndPreds+1];
  				  		  int colno[numOfGndPreds+1];

  				  		  for (int predId = 0; predId < numOfGndPreds; ++predId) {
  				  			  GroundPredicate* gndPred = gndClause->getGroundPredicate(predId,gndPredHashArray);
  				  			  int predIndex = state_->getGndPredIndex(gndPred);

  				  			  //if (ilpdebug_) {
  				  				//cout << "predIndex: " << predIndex << endl;
  				  				//cout << "predSense: " << gndClause->getGroundPredicateSense(predId) << endl;
  				  			  //}

  				  			  if (gndClause->getGroundPredicateSense(predId)) {
  				  				  colno[predId] = predIndex+1;
  				  				  sparserow[predId] = 1.0;
  				  			  }
  				  			  else {
  				  				  colno[predId] = predIndex+1;
  				  				  sparserow[predId] = -1.0;
  				  				  lowerBound -= 1;
  				  			  }
  						  }

  				  		  // put the coefficient of the auxiliary variable at the end position of this vector
  				  		  colno[numOfGndPreds] = numVar;
  				  		  sparserow[numOfGndPreds] = -1;

  				  		  ret = add_constraintex(lp, numOfGndPreds+1, sparserow, colno, GE, lowerBound);
  				  		  numCon++;
  				  	  	}
  			  	  }
  				  else {
	  				  // Clause with negative weight
	  				  // In this case we need to add one constraint for each grounding predicate in the clause
	  				  if (ilpdebug_) {
			  			  cout << "Adding constraint for each grounding predicate in this negative clause ... " << endl;
			  		  }

	  				  // Add the coefficient of this variable to the objective function
				  	  if (ret == 1)
				  		  ret = set_obj(lp,numVar,-wt);

	  				  for (int predId = 0; predId < numOfGndPreds; ++predId) {
	  					  int colno[2];
	  					  double sparserow[2];

					  	  double lowerBound = 0;

	  					  GroundPredicate* gndPred = gndClause->getGroundPredicate(predId,gndPredHashArray);
	  					  int predIndex = state_->getGndPredIndex(gndPred);

	  					  if (gndClause->getGroundPredicateSense(predId)) {
				  				  colno[0] = predIndex+1;
				  				  sparserow[0] = -1.0;
				  				  lowerBound -= 1;
			  			  }
			  			  else {
			  				  colno[0] = predIndex+1;
			  				  sparserow[0] = 1.0;
			  			  }
				  		  colno[1] = numVar;
				  		  sparserow[1] = -1;

				  		  ret = add_constraintex(lp, 2, sparserow, colno, GE, lowerBound);
				  		  numCon++;
	  				  }
		  			}
  	  		  	}
  	  		}
	  }
	  
	  // adding another dummy variable to fix lpsolve problem
	  add_columnex(lp,0, NULL, NULL);
	  set_bounds(lp,numVar,0,1);
	  set_int(lp,numVar,TRUE);
	  

	  if (ilpdebug_) {
		  cout << "Number of variables: " << numVar << endl;
		  cout << "Number of constraints: " << numCon << endl;
	  }


	    if (lossAugmentedInfer_) {
	      for (int j = 0; j < numOfKnownPreds; ++j) {
	          GroundPredicate* gndPred = (*knePreds)[j];
	          int predInd = state_->getGndPredIndex(gndPred);
	          if ((*knePredValues)[j] == TRUE){
	        	  switch (lossFunction_) {
	        	  	case HAMMING:
	        	  		coff[predInd] -= 1;
	        	  		break;
	        	  	case F1:
	        	  		coff[predInd] -= 2;
	        	  }
	          }
	          else {
	        	  coff[predInd] += 1;
	          }
	      }
	      for (int j = 0; j < numOfUnknownPreds; ++j) {
		          GroundPredicate* gndPred = (*unePreds)[j];
		          int predInd = state_->getGndPredIndex(gndPred);
		          coff[predInd] += 1;
		      }

	    }

	    if (ret ==1) {
		    for(int j=0; j < numOfGndPredicates; ++j) {
		    	if (coff[j])
		    		ret = set_obj(lp,j+1,coff[j]);
			}
	    }

	    if (ret == 1) {
	    	set_maxim(lp);
	    }

	    if (ilpdebug_) {
	    	print_lp(lp);
	    }

	    if (ret == 1) {
	    	if (!LPRelaxation_)
	    		cout << "Running LPSolve to solve the current ILP problem ... " << endl;
	    	else
	    		cout << "Running LPSolve to solve the current LP relaxation problem ... " << endl;
	    	ret = solve(lp);;
	    }
    }

    double *xx;

    if ( ret==0)
    {
      if (!LPRelaxation_)
      {
    	  cout << "Getting the solution for the current ILP problem... " << endl;
    	  get_ptr_variables(lp, &xx);
      }
      else
      {
    	  cout << "Getting the solution for the current LP relaxation problem... " << endl;
    	  get_ptr_variables(lp, &xx);
      }

      if (ilpdebug_) {
	      printf("Primal solution\n");
	      for(int j=0; j<numOfGndPredicates; ++j)
	        printf("x[%d]: %e\n",j,xx[j]);
      }
    }

	if (LPRelaxation_){
	  	// rounding the LP solution to integer value
	  	roundingLPSolution(xx, numOfGndPredicates);
	}

  	for (int i = 0; i < numOfGndPredicates; ++i) {
  	  	GroundPredicate* gndPred = (*gndPredHashArray)[i];
  	  	int predInd = state_->getGndPredIndex(gndPred);
  	  	int sol = xx[predInd];
  	  	if (ilpdebug_) {
  			cout << "Predicate " << (i+1) << ": ";
  			gndPred->print(cout,domain);
  			cout << endl;
  			cout << "predIndex: " << predInd << endl;
  		}
  	  	if (sol) {
  	  		if (ilpdebug_)
  	    		cout << "Infered value: TRUE" << endl;
  			state_->setValueOfAtom(predInd+1,true,false,-1);
  			gndPred->setTruthValue(true);
  	  	}
  	  	else {
  	  		if (ilpdebug_)
  	    		cout << "Infered value: FALSE" << endl;
  			state_->setValueOfAtom(predInd+1,false,false,-1);
  			gndPred->setTruthValue(false);
  	  	}
  	}
      state_->saveLowState();

      // cleanup
      delete_lp(lp);

      cout << "Leaving ILPInference::infer" << endl;
    }

  void inferMosek()
  {
    cout << "ILP solver: Mosek" << endl;
	// get query predicate id
    const Domain* domain = state_->getDomain();
    const GroundPredicateHashArray* knePreds = state_->getKnePreds();
    const GroundPredicateHashArray* unePreds = state_->getUnePreds();
    const GroundPredicateHashArray* gndPredHashArray = state_->getGndPredHashArrayPtr();
    const Array<TruthValue>* knePredValues = state_->getKnePredValues();
    int numOfKnownPreds = 0;
    int numOfUnknownPreds = 0;
    int numOfGndClauses = state_->getNumClauses();
    int numOfGndPredicates = state_->getNumAtoms();

    if (knePreds != NULL){
    	numOfKnownPreds = knePreds->size();
    }
    if (unePreds != NULL) {
    	numOfUnknownPreds = unePreds->size();
    }

    if (ilpdebug_){
    	cout << "Number of grounding predicates: " << numOfGndPredicates << endl;
    	cout << "Number of grounding clauses: " << numOfGndClauses << endl;
    }

    // Setup the LP solver
    int MAXNUMVAR = numOfGndClauses + numOfGndPredicates;
    int MAXNUMCON = numOfGndClauses*2;
    //double        xx[MAXNUMVAR];
    MSKenv_t      env;
    MSKtask_t     task;
    MSKrescodee   r;
    MSKintt numvar,numcon;
    //int numVar = numOfGndPredicates;


    // Create the mosek environment.
    r = MSK_makeenv(&env,NULL,NULL,NULL,NULL);

    // Check whether the return code is ok.
    if ( r==MSK_RES_OK )
    {
  	  // Directs the log stream to the 'printstr' function.
  	  MSK_linkfunctoenvstream(env,
                            MSK_STREAM_LOG,
                            NULL,
                            printstr);
    }

    // Initialize the environment.
    r = MSK_initenv(env);

    if ( r==MSK_RES_OK )
    {
  	  // Create the optimization task.
  	  r = MSK_maketask(env,MAXNUMCON,MAXNUMVAR,&task);

  	  // Directs the log task stream to the 'printstr' function.
  	  MSK_linkfunctotaskstream(task,MSK_STREAM_LOG,NULL,printstr);

  	  // Give MOSEK an estimate of the size of the input data. This is done to increase the efficiency of inputting data, however it is optional.
  	  if (r == MSK_RES_OK)
  		  r = MSK_putmaxnumvar(task,MAXNUMVAR);

  	  if (r == MSK_RES_OK)
  		  r = MSK_putmaxnumcon(task,MAXNUMCON);

  	  // Append the variables for grounding predicates.
  	  if (ilpdebug_) {
  		  cout << "Creating a variable for each grounding predicate ... " << endl;
  	  }
  	  if (r == MSK_RES_OK)
  		  r = MSK_append(task,MSK_ACC_VAR,numOfGndPredicates);

  	  if (ilpdebug_) {
  		  cout << "Putting variable bound and constraints ... " << endl;
  	  }
  	  // Put variable bound and constraints
	  if (r == MSK_RES_OK) {
		  for(int j=0; j < numOfGndPredicates; ++j) {
			  r = MSK_putbound(task,MSK_ACC_VAR,j,MSK_BK_RA,0,1);
			  if (!LPRelaxation_)
				  r = MSK_putvartype(task,j,MSK_VAR_TYPE_INT);
		  }
	  }

  	  if (ilpdebug_) {
  		  cout << "Initializing coff ... " << endl;
  	  }
  	  double coff[numOfGndPredicates];
  	  for (int i = 0; i < numOfGndPredicates; ++i) {
			coff[i] = 0;
	  }

  	  if (ilpdebug_) {
  		  cout << "Process each ground clause ... " << endl;
  	  }

  	  for (int clauseInd = 0; clauseInd < numOfGndClauses; clauseInd++) {
  		  GroundClause* gndClause = state_->getGndClause(clauseInd);
  		  gndClause->setSatisfied(false);
  		  if (ilpdebug_) {
  			  gndClause->printWithWtAndStrVar(cout,state_->getDomain(),gndPredHashArray);
  			  cout << endl;
  		  }

  		  double wt = gndClause->getWt();
  		  double hardWt = state_->getHardWt();
  		  if (hardWt > 1000000) {
  			  hardWt = 1000000;
  		  }

  		  if (wt >= hardWt) {
  			  if (ilpdebug_) {
				  cout << "This is a hard clause, adding a constraint for it ..." << endl;
	  		  }

  			  int lowerBound = 1;
  			  int numOfGndPreds = gndClause->getNumGroundPredicates();

  			  // Append a new constraint
	          if (r == MSK_RES_OK)
	        	  r = MSK_append(task,MSK_ACC_CON,1);

		  	  // Get index of new constraint
		  	  if (r == MSK_RES_OK)
		  		  r = MSK_getnumcon(task,&numcon);

		  	  // Put new values in the A matrix
	  		  MSKidxt arowsub[numOfGndPreds];
	  		  double arowval[numOfGndPreds];

	  		  for (int predId = 0; predId < numOfGndPreds; ++predId) {
	  			  GroundPredicate* gndPred = gndClause->getGroundPredicate(predId,gndPredHashArray);
	  			  int predIndex = state_->getGndPredIndex(gndPred);

	  			  if (gndClause->getGroundPredicateSense(predId)) {
	  				  arowsub[predId] = predIndex;
	  				  arowval[predId] = 1.0;
	  			  }
	  			  else {
	  				  arowsub[predId] = predIndex;
	  				  arowval[predId] = -1.0;
	  				  lowerBound -= 1;
	  			  }
			  }

	  		  if (r == MSK_RES_OK)
	  			  r = MSK_putavec(task, MSK_ACC_CON, numcon-1, numOfGndPreds, arowsub, arowval);
	  		  // Set bounds on new constraint
		  	  if (r == MSK_RES_OK)
		  		 r = MSK_putbound(task, MSK_ACC_CON, numcon-1, MSK_BK_LO, lowerBound, +MSK_INFINITY);

		  	  continue;
		  }
  		  if (wt) {

		  	  int numOfGndPreds = gndClause->getNumGroundPredicates();

	  		  if (numOfGndPreds == 1){
	  			  // It's unit clause, we don't need to have an auxiliary variable for this clause
	  			  GroundPredicate* gndPred = gndClause->getGroundPredicate(0,gndPredHashArray);
	  			  int predIndex = state_->getGndPredIndex(gndPred);

	  			  if (ilpdebug_) {
	  				//cout << "predIndex: " << predIndex << endl;
	  				//cout << "predSense: " << gndClause->getGroundPredicateSense(0) << endl;
	  			  }

	  			  if (gndClause->getGroundPredicateSense(0))
	  				  coff[predIndex] = wt;
	  			  else
	  				  coff[predIndex] = -wt;
	  		  }
	  		  else {

	  			  if (ilpdebug_) {
		  			  cout << "Adding a new variable for this clause ... " << endl;
		  		  }

	  			  if (r == MSK_RES_OK)
	  				r = MSK_append(task,MSK_ACC_VAR,1);

	  			  // Get index of new variable
			  	  if (r == MSK_RES_OK)
			  		  r = MSK_getnumvar(task,&numvar);

		  		  if (r == MSK_RES_OK) {
		  			  r = MSK_putbound(task,MSK_ACC_VAR,numvar-1,MSK_BK_RA,0,1);
		  			  if (!LPRelaxation_)
		  				  r = MSK_putvartype(task,numvar-1,MSK_VAR_TYPE_INT);
		  		  }

	  			  if (wt > 0) {
	  				  // Clause with positive weight
	  				  // In this case, we only need one constraint

	  				  // Add the coefficient of this variable to the objective function
				  	  if (r == MSK_RES_OK)
				  		  r = MSK_putcj(task,numvar-1,wt);

				  	  // Append a new constraint
				  	  if (ilpdebug_) {
			  			  cout << "Adding the constraint for this positive clause ... " << endl;
			  		  }

			          if (r == MSK_RES_OK)
			        	  r = MSK_append(task,MSK_ACC_CON,1);

				  	  // Get index of new constraint
				  	  if (r == MSK_RES_OK)
				  		  r = MSK_getnumcon(task,&numcon);

				  	  int lowerBound = 0;

				  	  // Put new values in the A matrix
				  	  if (r == MSK_RES_OK) {
				  		  MSKidxt arowsub[numOfGndPreds+1];
				  		  double arowval[numOfGndPreds+1];

				  		  for (int predId = 0; predId < numOfGndPreds; ++predId) {
				  			  GroundPredicate* gndPred = gndClause->getGroundPredicate(predId,gndPredHashArray);
				  			  int predIndex = state_->getGndPredIndex(gndPred);

				  			  //if (ilpdebug_) {
				  				//cout << "predIndex: " << predIndex << endl;
				  				//cout << "predSense: " << gndClause->getGroundPredicateSense(predId) << endl;
				  			  //}

				  			  if (gndClause->getGroundPredicateSense(predId)) {
				  				  arowsub[predId] = predIndex;
				  				  arowval[predId] = 1.0;
				  			  }
				  			  else {
				  				  arowsub[predId] = predIndex;
				  				  arowval[predId] = -1.0;
				  				  lowerBound -= 1;
				  			  }
						  }

				  		  // put the coefficient of the auxiliary variable at the end position of this vector
				  		  arowsub[numOfGndPreds] = numvar-1;
				  		  arowval[numOfGndPreds] = -1;

				  		  r = MSK_putavec(task, MSK_ACC_CON, numcon-1, numOfGndPreds+1, arowsub, arowval);
				      }

				  	  //if (ilpdebug_) {
				  		  //cout << "Lower bound: " << lowerBound << endl;
					  //}

				  	  // Set bounds on new constraint
				  	  if (r == MSK_RES_OK)
				  		 r = MSK_putbound(task, MSK_ACC_CON, numcon-1, MSK_BK_LO, lowerBound, +MSK_INFINITY);

	  			  }

	  			  else {
	  				  // Clause with negative weight
	  				  // In this case we need to add one constraint for each grounding predicate in the clause
	  				  if (ilpdebug_) {
			  			  cout << "Adding constraint for each grounding predicate in this negative clause ... " << endl;
			  		  }

	  				  // Add the coefficient of this variable to the objective function
				  	  if (r == MSK_RES_OK)
				  		  r = MSK_putcj(task,numvar-1,-wt);

	  				  for (int predId = 0; predId < numOfGndPreds; ++predId) {
	  					  MSKidxt arowsub[2];
	  					  double arowval[2];

	  					  if (r == MSK_RES_OK)
				        	  r = MSK_append(task,MSK_ACC_CON,1);

					  	  // Get index of new constraint
					  	  if (r == MSK_RES_OK)
					  		  r = MSK_getnumcon(task,&numcon);

					  	  int lowerBound = 0;

	  					  GroundPredicate* gndPred = gndClause->getGroundPredicate(predId,gndPredHashArray);
	  					  int predIndex = state_->getGndPredIndex(gndPred);

	  					  if (gndClause->getGroundPredicateSense(predId)) {
				  				  arowsub[0] = predIndex;
				  				  arowval[0] = -1.0;
				  				  lowerBound -= 1;
			  			  }
			  			  else {
			  				  arowsub[0] = predIndex;
			  				  arowval[0] = 1.0;
			  			  }
				  		  arowsub[1] = numvar-1;
				  		  arowval[1] = -1;

				  		  if (r == MSK_RES_OK)
				  			  r = MSK_putavec(task, MSK_ACC_CON, numcon-1, 2, arowsub, arowval);

		  				  // Set bounds on new constraint
					  	  if (r == MSK_RES_OK)
					  		  r = MSK_putbound(task, MSK_ACC_CON, numcon-1, MSK_BK_LO, lowerBound, +MSK_INFINITY);
	  				  }
	  			  }
				}
	  	  }
  	  }

  	  if (r == MSK_RES_OK)
  		  r = MSK_getnumvar(task,&numvar);

  	  if (r == MSK_RES_OK)
  		  r = MSK_getnumcon(task,&numcon);

  	  if (ilpdebug_) {
  		  cout << "Number of variables: " << numvar << endl;
  		  cout << "Number of constraints: " << numcon << endl;
  	  }

		/* Put constant C */
	    if (r == MSK_RES_OK)
	    	r = MSK_putcfix(task, 0.0);

	    /* Put vector c */
	    if (lossAugmentedInfer_) {
	      for (int j = 0; j < numOfKnownPreds; ++j) {
	          GroundPredicate* gndPred = (*knePreds)[j];
	          int predInd = state_->getGndPredIndex(gndPred);
	          if ((*knePredValues)[j] == TRUE){
	        	  switch (lossFunction_) {
  	        	  	case HAMMING:
  	        	  		coff[predInd] -= 1;
  	        	  		break;
  	        	  	case F1:
  	        	  		coff[predInd] -= 2;
  	        	  }
	          }
	          else {
	        	  coff[predInd] += 1;
	          }
	      }
	      for (int j = 0; j < numOfUnknownPreds; ++j) {
  	          GroundPredicate* gndPred = (*unePreds)[j];
  	          int predInd = state_->getGndPredIndex(gndPred);
  	          coff[predInd] += 1;
  	      }

	    }

	    for(int j=0; j < numOfGndPredicates; ++j) {
	    	if (coff[j])
	    		r = MSK_putcj(task,j,coff[j]);
		}

	    if (r == MSK_RES_OK) {
	    	MSK_putobjsense(task,MSK_OBJECTIVE_SENSE_MAXIMIZE);
	    }

	    if (ilpdebug_) {
		  r = MSKAPI MSK_printdata (
		      task, //MSKtask_t task,
		      MSK_STREAM_LOG, //MSKstreamtypee whichstream,
		      0, //MSKidxt firsti,
		      numcon, //MSKidxt lasti,
		      0, //MSKidxt firstj,
		      numvar, //MSKidxt lastj,
		      0, //MSKidxt firstk,
		      0, //MSKidxt lastk,
		      1, //MSKintt c,
		      1, //MSKintt qo,
		      1, //MSKintt a,
		      0, //MSKintt qc,
		      1, //MSKintt bc,
		      0, //MSKintt bx,
		      0, //MSKintt vartype,
		      0 //MSKintt cones);
		      );
	    }

	    if (r == MSK_RES_OK) {
	    	if (!LPRelaxation_)
	    		cout << "Running Mosek to solve the current ILP problem ... " << endl;
	    	else
	    		cout << "Running Mosek to solve the current LP relaxation problem ... " << endl;
	    	MSK_optimize(task);
	    }
    }
    double xx[numOfGndPredicates];

    if ( r==MSK_RES_OK )
    {
      if (!LPRelaxation_)
      {
    	  cout << "Getting the solution for the current ILP problem... " << endl;
    	  MSK_getsolutionslice(task,
    		  			   MSK_SOL_ITG,
                           MSK_SOL_ITEM_XX,
                           0,
                           numOfGndPredicates,
                           xx);
      }
      else
      {
    	  cout << "Getting the solution for the current LP relaxation problem... " << endl;
    	  MSK_getsolutionslice(task,
    	      		  	   MSK_SOL_BAS,
    	                   MSK_SOL_ITEM_XX,
    	                   0,
    	                   numOfGndPredicates,
    	                   xx);
      }

      if (ilpdebug_) {
	      printf("Primal solution\n");
	      for(int j=0; j<numOfGndPredicates; ++j)
	        printf("x[%d]: %e\n",j,xx[j]);
      }
    }

    if (LPRelaxation_){
    	// rounding the LP solution to integer value
    	roundingLPSolution(xx, numOfGndPredicates);
    }

	for (int i = 0; i < numOfGndPredicates; ++i) {
	  	GroundPredicate* gndPred = (*gndPredHashArray)[i];
	  	int predInd = state_->getGndPredIndex(gndPred);
	  	int sol = xx[predInd];
	  	if (ilpdebug_) {
			cout << "Predicate " << (i+1) << ": ";
			gndPred->print(cout,domain);
			cout << endl;
			cout << "predIndex: " << predInd << endl;
		}
	  	if (sol) {
	  		if (ilpdebug_)
	    		cout << "Infered value: TRUE" << endl;
			state_->setValueOfAtom(predInd+1,true,false,-1);
			gndPred->setTruthValue(true);
	  	}
	  	else {
	  		if (ilpdebug_)
	    		cout << "Infered value: FALSE" << endl;
			state_->setValueOfAtom(predInd+1,false,false,-1);
			gndPred->setTruthValue(false);
	  	}
	}
    state_->saveLowState();

    // cleanup
    MSK_deletetask(&task);
    MSK_deleteenv(&env);

    cout << "Leaving ILPInference::infer" << endl;
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

    int idx = state_->getGndPredIndex(gndPred);
    int truthValue = 0;
    if (idx >= 0) truthValue = state_->getValueOfLowAtom(idx + 1);
    return truthValue;
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
	 void roundUp(double sol[], int size){
		 const Domain* domain = state_->getDomain();
		 Array<int> fractionals;

		 for (int i = 0; i < size; ++i) {
			 if (sol[i] == 1.0) {
				 GroundPredicate* gndPred = state_->getGndPred(i);
				 const Array<GroundClause*>*  posGndClauses = gndPred->getPosGndClauses();
				 for (int i=0; i < posGndClauses->size(); i++){
	 	 	  		GroundClause* gndClause = (*posGndClauses)[i];
	 	 	  		gndClause->setSatisfied(true);
	 	 	  		/*
	 	 	  		if (ilpdebug_) {
	 	 	  			gndClause->print(cout,domain,state_->getGndPredHashArrayPtr());
	 	 	  			cout << endl;
	 	 	  		}
	 	 	  		*/
	 	 	  	 }
			 }
			 else if (sol[i] == 0.0) {
				 GroundPredicate* gndPred = state_->getGndPred(i);
				 const Array<GroundClause*>*  negGndClauses = gndPred->getNegGndClauses();
 				 for (int i=0; i < negGndClauses->size(); i++){
 	 	 	  		GroundClause* gndClause = (*negGndClauses)[i];
 	 	 	  		gndClause->setSatisfied(true);
 	 	 	  		/*
 	 	 	  		if (ilpdebug_) {
 	 	 	  			gndClause->print(cout,domain,state_->getGndPredHashArrayPtr());
 	 	 	  			cout << endl;
 	 	 	  		}
 	 	 	  		*/
 	 	 	  	 }
			 }
			 else {
				 fractionals.append(i);
			 }
		}
		cout << "Number of fractional solutions: " << fractionals.size() << "/" << size << endl;
		while (!fractionals.empty()) {
			int predInd = fractionals.removeLastItem();
			if (ilpdebug_) {
				cout << "Rounding the value of xx[" << predInd << "] ..." << endl;
				cout << "xx[" << predInd << "] = " << sol[predInd] << endl;
			}

			GroundPredicate* gndPred = state_->getGndPred(predInd);
			double delta = 0;
			const Array<GroundClause*>*  posGndClauses = gndPred->getPosGndClauses();
			for (int i=0; i < posGndClauses->size(); i++){
 	 	  		GroundClause* gndClause = (*posGndClauses)[i];
 	 	  		if (!gndClause->isSatisfied()) {
 	 	  			if (gndClause->getWt() > 1000)
 	 	  				delta += 1000;
 	 	  			else
 	 	  			 delta += gndClause->getWt();
 	 	  		}
 	 	  	}

			const Array<GroundClause*>*  negGndClauses = gndPred->getNegGndClauses();
			for (int i=0; i < negGndClauses->size(); i++){
 	 	  		GroundClause* gndClause = (*negGndClauses)[i];
 	 	  		if (!gndClause->isSatisfied()) {
 	 	  			if (gndClause->getWt() > 1000)
 	 	  		 	  delta -= 1000;
 	 	  		 	else
 	 	  		 	  delta -= gndClause->getWt();
 	 	  		}
 	 	  	}

			if (delta > 0) {
				sol[predInd] = 1;
				for (int i=0; i < posGndClauses->size(); i++){
					GroundClause* gndClause = (*posGndClauses)[i];
					gndClause->setSatisfied(true);
				}
			}
			else {
				sol[predInd] = 0;
				for (int i=0; i < negGndClauses->size(); i++){
	 	 	  		GroundClause* gndClause = (*negGndClauses)[i];
	 	 	  		gndClause->setSatisfied(true);
	 	 	  	}
			}
			if (ilpdebug_) {
				cout << "Delta_i = " << delta << endl;
				cout << "sol[" << predInd << "] = " << sol[predInd] << endl;
			}
		}
	 }

	 void roundUp1(double sol[], int size){
	 		 const Domain* domain = state_->getDomain();
	 		 Array<int> fractionals;

	 		 double threshold = 0.999;

	 		 for (int i = 0; i < size; ++i) {
	 			 if (sol[i] >= threshold) {
	 				 sol[i] = 1;
	 				 GroundPredicate* gndPred = state_->getGndPred(i);
	 				 const Array<GroundClause*>*  posGndClauses = gndPred->getPosGndClauses();
	 				 for (int i=0; i < posGndClauses->size(); i++){
	 	 	 	  		GroundClause* gndClause = (*posGndClauses)[i];
	 	 	 	  		gndClause->setSatisfied(true);
	 	 	 	  		/*
	 	 	 	  		if (ilpdebug_) {
	 	 	 	  			gndClause->print(cout,domain,state_->getGndPredHashArrayPtr());
	 	 	 	  			cout << endl;
	 	 	 	  		}
	 	 	 	  		*/
	 	 	 	  	 }
	 			 }
	 			 else if (sol[i] <= (1-threshold)) {
	 				 sol[i] = 0;
	 				 GroundPredicate* gndPred = state_->getGndPred(i);
	 				 const Array<GroundClause*>*  negGndClauses = gndPred->getNegGndClauses();
	  				 for (int i=0; i < negGndClauses->size(); i++){
	  	 	 	  		GroundClause* gndClause = (*negGndClauses)[i];
	  	 	 	  		gndClause->setSatisfied(true);
	  	 	 	  		/*
	  	 	 	  		if (ilpdebug_) {
	  	 	 	  			gndClause->print(cout,domain,state_->getGndPredHashArrayPtr());
	  	 	 	  			cout << endl;
	  	 	 	  		}
	  	 	 	  		*/
	  	 	 	  	 }
	 			 }
	 			 else {
	 				 fractionals.append(i);
	 			 }
	 		}
	 		cout << "Number of fractional solutions: " << fractionals.size() << "/" << size << endl;
	 		while (!fractionals.empty()) {
	 			int predInd = fractionals.removeLastItem();
	 			if (ilpdebug_) {
	 				cout << "Rounding the value of xx[" << predInd << "] ..." << endl;
	 				cout << "xx[" << predInd << "] = " << sol[predInd] << endl;
	 			}

	 			GroundPredicate* gndPred = state_->getGndPred(predInd);
	 			double delta = 0;
	 			const Array<GroundClause*>*  posGndClauses = gndPred->getPosGndClauses();
	 			for (int i=0; i < posGndClauses->size(); i++){
	  	 	  		GroundClause* gndClause = (*posGndClauses)[i];
	  	 	  		if (!gndClause->isSatisfied()) {
	  	 	  			if (gndClause->getWt() > 1000)
	  	 	  				delta += 1000;
	  	 	  			else
	  	 	  			 delta += gndClause->getWt();
	  	 	  		}
	  	 	  	}

	 			const Array<GroundClause*>*  negGndClauses = gndPred->getNegGndClauses();
	 			for (int i=0; i < negGndClauses->size(); i++){
	  	 	  		GroundClause* gndClause = (*negGndClauses)[i];
	  	 	  		if (!gndClause->isSatisfied()) {
	  	 	  			if (gndClause->getWt() > 1000)
	  	 	  		 	  delta -= 1000;
	  	 	  		 	else
	  	 	  		 	  delta -= gndClause->getWt();
	  	 	  		}
	  	 	  	}

	 			if (delta > 0) {
	 				sol[predInd] = 1;
	 				for (int i=0; i < posGndClauses->size(); i++){
	 					GroundClause* gndClause = (*posGndClauses)[i];
	 					gndClause->setSatisfied(true);
	 				}
	 			}
	 			else {
	 				sol[predInd] = 0;
	 				for (int i=0; i < negGndClauses->size(); i++){
	 	 	 	  		GroundClause* gndClause = (*negGndClauses)[i];
	 	 	 	  		gndClause->setSatisfied(true);
	 	 	 	  	}
	 			}
	 			if (ilpdebug_) {
	 				cout << "Delta_i = " << delta << endl;
	 				cout << "sol[" << predInd << "] = " << sol[predInd] << endl;
	 			}
	 		}
	 	 }


	 void roundingLPSolution(double sol[], int size){
		 switch (roundingScheme_) {
			 case DIRECT:
				 cout << endl << "Direct rounding from the LP solution..." << endl;
				 break;
			 case F3:
				 cout << endl << "Rounding using function f3..." << endl;
				 break;
			 case F4:
				 cout << endl << "Rounding using function f4..." << endl;
				 break;
			 case ROUNDUP:
				 cout << endl << "Rounding using ROUND_UP procedure... " << endl;
				 roundUp(sol,size);
				 return;
			 case ROUNDUP1:
 				 cout << endl << "Rounding using ROUND_UP1 procedure... " << endl;
 				 roundUp1(sol,size);
 				 return;
		 }
		 /* initialize random seed: */
		 //Ran ran(time(NULL));
		 for (int i = 0; i < size; ++i) {
			 double y = sol[i];
			 /*
			 // not rounding non-fractional solution
			 if ((y ==0) || (y ==1))
				 continue;
			 */
			 double f_y = 0;
			 switch (roundingScheme_) {
				 case DIRECT:
					 f_y = y;
					 break;
				 case F3:
  					 if (y < 0.5)
  						 f_y = 1 - pow (4,-y);
  					 else
  						 f_y = pow(4, y -1);
  					 break;
				 case F4:
 					 if (y <= 0.3)
 						 f_y = (5.0/6.0)*y + 1.0/6.0;
 					 else if ((0.3 < y) and (y <= 0.7))
 							 f_y = (5.0/12.0)*y + 7.0/24.0;
 					 else
 						 f_y = (5.0/6.0)*y;
 					 break;

			 }

			 //double ranNum = ran.doub();
			 double ranNum = drand48();

			 if (ranNum <= f_y)
				 sol[i] = 1;
			 else
				 sol[i] = 0;
			 if (ilpdebug_){
				 cout << "Rounding the value of xx[" << i << "] ..." << endl;
				 cout << "y = " << y << ";\t";
				 cout << "f_y = " << f_y << ";\t";
				 cout << "ranNum = " << ranNum << ";\t";
				 cout << "sol[" << i << "] = " << sol[i] << endl;
			 }
		}
	 }



 double * probs_;
 bool ilpdebug_;
 bool lossAugmentedInfer_;
 bool LPRelaxation_;
 int solver_ ;
 int roundingScheme_;
 int lossFunction_;
 double lossScale_;
 public:
     // Different ILP & LP solver
   const static int MOSEK = 1;
   const static int LPSOLVE = 2;
   // Different rounding scheme
   const static int DIRECT = 1;
   const static int F3 = 2;
   const static int F4 = 3;
   const static int ROUNDUP = 4;
   const static int ROUNDUP1 = 5;
   // Different loss function
   const static int HAMMING = 1; // Number of misclassified atoms
   const static int F1 = 2;
};

#endif /*UTILPINFER_H_*/
