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
#ifndef MAX_MARGIN_LEARNER_H_MAY_13_2008
#define MAX_MARGIN_LEARNER_H_MAY_13_2008

#include <stdio.h>
#include "infer.h"
#include "clause.h"
#include "timer.h"
#include "indextranslator.h"
#include "maxwalksat.h"
//#include "discriminativelearner.h"
#include "mosek.h" /* Include the MOSEK definition file. */

const double EPSILON = .00001;

/*
static void MSKAPI printstr(void *handle, char str[])
{
	printf("%s",str);
} /* printstr */


/**
 * Max Margin learning algorithms (see "Max Margin Training of Markov
 * Logic Networks", Tuyen N Huynh and Raymond J. Mooney, 2008).
 */
class MaxMarginLearner
{
 public:

  /**
   * Constructor. Various variables are initialized, relevant clauses are
   * determined and weights and inference procedures are initialized.
   *
   * @param inferences Array of inference procedures to be used for inference
   * in each domain.
   * @param nonEvidPredNames Names of non-evidence predicates. This is used to
   * determine the relevant clauses.
   * @param idxTrans IndexTranslator needed when multiple dbs are used and they
   * don't line up.
   * @param lazyInference If true, lazy inference is used.
   * @param withEM If true, EM is used to fill in missing values.
   */
  MaxMarginLearner(const Array<Inference*>& inferences,
                        const StringHashArray& nonEvidPredNames,
                        IndexTranslator* const & idxTrans,
                        const bool& lazyInference, const bool& withEM, const bool& debug)
    : domainCnt_(inferences.size()), idxTrans_(idxTrans),
      lazyInference_(lazyInference), backtrackCount_(0), withEM_(withEM), dldebug(debug)
  {
    cout << endl << "Constructing max margin learner..." << endl << endl;

    inferences_.append(inferences);
    //logOddsPerDomain_.growToSize(domainCnt_);
    clauseCntPerDomain_.growToSize(domainCnt_);

    for (int i = 0; i < domainCnt_; i++)
    {
      clauseCntPerDomain_[i] =
        inferences_[i]->getState()->getMLN()->getNumClauses();
      //logOddsPerDomain_[i].growToSize(clauseCntPerDomain_[i], 0);
    }

    if (lazyInference_){
    	totalTrueCnts_.growToSize(domainCnt_);
    	totalFalseCnts_.growToSize(domainCnt_);
    	defaultTrueCnts_.growToSize(domainCnt_);
    	defaultFalseCnts_.growToSize(domainCnt_);
    }
    relevantClausesPerDomain_.growToSize(domainCnt_);
    //relevantClausesFormulas_ is set in findRelevantClausesFormulas()
    unknownPreds_.growToSize(domainCnt_);

    findRelevantClauses(nonEvidPredNames);
    findRelevantClausesFormulas();

      // Initialize the clause wts
    initializeWts(nonEvidPredNames);

      // Initialize the inference / state
    for (int i = 0; i < inferences_.size(); i++)
      inferences_[i]->init();
  }

  ~MaxMarginLearner()
  {
    for (int i = 0; i < trainTrueCnts_.size(); i++)
    {
      delete[] trainTrueCnts_[i];
      delete[] trainFalseCnts_[i];
    }

    /*
    for (int j = 0; j < domainCnt_; j++)
    {
    	delete[] unknownPreds_[j];
    	delete[] relevantClausesPerDomain_[j];
    }
    */
  }

  void setMLNWeights(double* const& weights)
  {
      // If there is one db or the clauses for multiple databases line up
    if (idxTrans_ == NULL)
    {
      int clauseCnt = clauseCntPerDomain_[0];
      for (int i = 0; i < domainCnt_; i++)
      {
        Array<bool>& relevantClauses = relevantClausesPerDomain_[i];
        assert(clauseCntPerDomain_[i] == clauseCnt);
        const MLN* mln = inferences_[i]->getState()->getMLN();
        VariableState* state = inferences_[i]->getState();

        for (int j = 0; j < clauseCnt; j++)
        {
          Clause* c = (Clause*) mln->getClause(j);
          if (c->isHardClause()) {
        	  if (dldebug) {
				  cout << "Set weight for this hard clause: " << endl;
				  c->printWithWtAndStrVar(cout,state->getDomain());
				  cout << endl << "Hard weight: " << state->getHardWt() << endl;
			  }
        	  c->setWt(state->getHardWt());
        	  continue;
          }
          if (relevantClauses[j]) c->setWt(weights[j]);
          else                    c->setWt(0);
        }
      }
    }
    else
    {   // The clauses for multiple databases do not line up
      Array<Array<double> >* wtsPerDomain = idxTrans_->getWtsPerDomain();
      const Array<Array<Array<IdxDiv>*> >* cIdxToCFIdxsPerDomain
        = idxTrans_->getClauseIdxToClauseFormulaIdxsPerDomain();

      for (int i = 0; i < domainCnt_; i++)
      {
        Array<double>& wts = (*wtsPerDomain)[i];
        memset((double*)wts.getItems(), 0, wts.size()*sizeof(double));

          //map clause/formula weights to clause weights
        for (int j = 0; j < wts.size(); j++)
        {
          Array<IdxDiv>* idxDivs = (*cIdxToCFIdxsPerDomain)[i][j];
          for (int k = 0; k < idxDivs->size(); k++)
            wts[j] += weights[ (*idxDivs)[k].idx ] / (*idxDivs)[k].div;
        }
      }

      for (int i = 0; i < domainCnt_; i++)
      {
        Array<bool>& relevantClauses = relevantClausesPerDomain_[i];
        int clauseCnt = clauseCntPerDomain_[i];
        Array<double>& wts = (*wtsPerDomain)[i];
        assert(wts.size() == clauseCnt);
        const MLN* mln = inferences_[i]->getState()->getMLN();
        VariableState* state = inferences_[i]->getState();

        for (int j = 0; j < clauseCnt; j++)
        {
          Clause* c = (Clause*) mln->getClause(j);
          if (c->isHardClause()) {
	      	  if (dldebug) {
				  cout << "Set weight for this hard clause: " << endl;
				  c->printWithWtAndStrVar(cout,state->getDomain());
				  cout << "Hard weight: " << state->getHardWt() << endl;
			  }
	      	  c->setWt(state->getHardWt());
	      	  continue;
	      }
          if(relevantClauses[j]) c->setWt(wts[j]);
          else                   c->setWt(0);
        }
      }
    }
  }

  void learnWeightsCP(double* const & weights, const int& numWeights,
  		  			const int& maxIter, const int& minIter, const double& maxSec,
  		  			const double& C, double epsilon, int lossFunction, double lossScale,
  		  			bool initWithLogOdds, bool nonMarginRescaling, bool ignoreUnknownQueryAtom,bool printLearnedWeightPerIter, bool nonRecursive)
    {
      Timer timer;
      double begSec = timer.time();

      cout << "2-norm max margin learning weights using cutting plane method... " << endl;

      double numOfExamples = 1;
      if (nonRecursive) {
    	  numOfExamples = 0;
    	  for (int i = 0; i < domainCnt_; i++)
		  {
			VariableState* state = inferences_[i]->getState();
			numOfExamples += state->getKnePredValues()->size();
		  }
      }
      //double numOfExamples = domainCnt_;

      cout << "Number of examples: " << numOfExamples << endl;
      cout << "Number of weights: " << numWeights << endl;

      memset(weights, 0, numWeights*sizeof(double));

      // Set the initial weight to the average log odds across domains/databases
      //if (initWithLogOdds)
      //	  setLogOddsWeights(weights, numWeights);

      double error = 1e+5;
      double slack = -1e+5;

      // Setup the QP solver
      int NUMVAR = numWeights + 1;
      int NUMCON = maxIter;
      int NUMQNZ = numWeights;
      double        qval[NUMQNZ];
      double        xx[NUMVAR];
      MSKenv_t      env;
      MSKtask_t     task;
      MSKrescodee   r;
      MSKidxt       qsubi[NUMQNZ];
      MSKidxt       qsubj[NUMQNZ];
      MSKintt numcon;


      /* Create the mosek environment. */
      r = MSK_makeenv(&env,NULL,NULL,NULL,NULL);

      /* Check whether the return code is ok. */
      if ( r==MSK_RES_OK )
      {
    	  /* Directs the log stream to the 'printstr' function. */
    	  MSK_linkfunctoenvstream(env,
                              MSK_STREAM_LOG,
                              NULL,
                              printstr);
      }

      /* Initialize the environment. */
      r = MSK_initenv(env);

      if ( r==MSK_RES_OK )
      {
    	  /* Create the optimization task. */
    	  r = MSK_maketask(env,NUMCON,NUMVAR,&task);

    	  /* Directs the log task stream to the 'printstr' function. */
    	  MSK_linkfunctotaskstream(task,MSK_STREAM_LOG,NULL,printstr);

    	  /* Give MOSEK an estimate of the size of the input data. This is done to increase the efficiency of inputting data, however it is optional.*/
    	  if (r == MSK_RES_OK)
    		  r = MSK_putmaxnumvar(task,NUMVAR);

    	  if (r == MSK_RES_OK)
    		  r = MSK_putmaxnumcon(task,NUMCON);

    	  /* Append the variables. */
    	  if (r == MSK_RES_OK)
    		  r = MSK_append(task,MSK_ACC_VAR,NUMVAR);

    	  /* Put c */
    	  if (r == MSK_RES_OK) {
    		  for(int j=0; j < NUMVAR-1; ++j) {
    			  r = MSK_putcj(task,j,0);
    		  }
    		  r = MSK_putcj(task,NUMVAR-1,C); // C*slack
    	  }

    	  /* Put variable bound */

    	  if (r == MSK_RES_OK) {
    		  for(int j=0; j < NUMVAR-1; ++j) {
    			  r = MSK_putbound(task,MSK_ACC_VAR,j,MSK_BK_FR,-MSK_INFINITY,+MSK_INFINITY);
    		  }
    		  r = MSK_putbound(task,MSK_ACC_VAR,NUMVAR-1,MSK_BK_LO,0,+MSK_INFINITY);
    	  }

    	  /* Input the Q for the objective. */
    	  if ( r==MSK_RES_OK )
	      {
	          /*
	           * The lower triangular part of the Q
	           * matrix in the objective is specified.
	           */
    		  for (int j = 0; j < numWeights; j++) {
    			  // (1/2)W'*W
    			  // MOSEK always assumes that there is a 1/2 in front of the w'Qw term in the objective
    			  qsubi[j] = j;   qsubj[j] = j;  qval[j] = 1;
    		  }

	          r = MSK_putqobj(task,NUMQNZ,qsubi,qsubj,qval);
	       }
      }

      int iter = 1;
      do {
    	  if (iter > maxIter) break;
    	  cout << endl << "Iteration " << iter << " : " << endl << endl;
    	  double totalsec = timer.time() - begSec;
          int hour = (int)totalsec/3600;
          int min = (int)(totalsec - 3600*hour)/60;
          int sec = (int)(totalsec - 3600*hour - 60*min);

            // Print time so far
          cout << "Elapsed time: " << totalsec << "s";
          if (hour > 0)
            cout << " (" << hour << "h " << min << "m " << sec << "s)";
          else if (min > 0)
            cout << " (" << min << "m " << sec << "s)";
          cout << endl;

          if (maxSec > 0 && totalsec > maxSec)
          {
            cout << "Time limit exceeded.  Stopping learning." << endl;
            break;
          }

          if (iter > 1) {
        	  //if (iter > 2) break;
        	  cout << "Learning the weights ... " << endl;
        	  if (dldebug) {
		    	  r = MSKAPI MSK_printdata (
		    	      task, //MSKtask_t task,
		    	      MSK_STREAM_LOG, //MSKstreamtypee whichstream,
		    	      0, //MSKidxt firsti,
		    	      numcon, //MSKidxt lasti,
		    	      0, //MSKidxt firstj,
		    	      NUMVAR, //MSKidxt lastj,
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

		      // Solve the QP problem
		      if ( r==MSK_RES_OK ) {
		    	  cout << "Running Mosek to solve the current QP problem ... " << endl;
		    	  r = MSK_optimize(task);
		    	  cout << "Return code: " << r << endl;
		      }

			  cout << "Getting the solution for the current QP problem... " << endl;
			  MSK_getsolutionslice(task,
								   MSK_SOL_ITR,
								   MSK_SOL_ITEM_XX,
								   0,
								   NUMVAR,
								   xx);
			  //printf("Primal solution\n");
			  //for(j=0; j<NUMVAR; ++j)
				//printf("x[%d]: %e\n",j,xx[j]);

			  if ( r==MSK_RES_OK )
			  {
		          bool converged = true;
		          int numOfNonZeroWts = 0;
		          for (int w = 0; w < numWeights; w++)
		          {
		        	  if (weights[w] != xx[w]) {
		        		  weights[w] = xx[w];
		        		  converged = false;
		        	  }
		        	  if (weights[w])
		        		  numOfNonZeroWts++;
		        	  if (dldebug)
		        		  cout << w << ":" << weights[w] << endl;
		          }
		          cout << "Number of non-zero weights: " << numOfNonZeroWts << endl;
		          if (slack != xx[NUMVAR-1]) {
		        	  slack = xx[NUMVAR-1];
		          }
		          cout << "Current slack value: " << slack << endl;
		          if (converged) {
		        	  cout << "Converged!" << endl;
		        	  break;
		          }
		      }
			  else {
				cout << "Encounter error when getting the solution of the current LP problem." << endl;
				cout << "Error code: " << r << endl;
				break;
			  }
          }

          if (printLearnedWeightPerIter) {
			  cout << endl << "Learned weights iteration " << iter << ":" << endl;
			  for (int w = 0; w < numWeights; w++)
			  {
				 cout << w << ":" << weights[w] << endl;
			  }
		  }
          cout << "Setting up weights ... " << endl;
          // Set the weights and run inference
          setMLNWeights(weights);

          cout << "Running inference ..." << endl;
          infer();
          cout << "Done with inference" << endl;

          double loss = calculateError(lossFunction,ignoreUnknownQueryAtom)/numOfExamples;
          loss = loss*lossScale;
          cout << "Current loss: " << loss << endl;

          Array<double*> inferredTrueCnts;
          Array<double*> inferredFalseCnts;

          inferredTrueCnts.growToSize(domainCnt_);
          //inferredFalseCnts.growToSize(domainCnt_);

          if (idxTrans_ == NULL) {
	          if (dldebug) cout << "Computing inferred counts... " << endl;
	          for (int i = 0; i < domainCnt_; i++)
	          {
	            if (dldebug) cout << "Domain " << i << endl;
	            int clauseCnt = clauseCntPerDomain_[i];
	            if (dldebug) cout << "Clause count: " << clauseCnt << endl;

	            inferredTrueCnts[i] = new double[clauseCnt];
	            //inferredFalseCnts[i] = new double[clauseCnt];

	            if (dldebug) cout<<"getting true cnts ... "<<endl;
	            VariableState* state = inferences_[i]->getState();
	            state->getNumClauseGndingsWithUnknown(inferredTrueCnts[i], clauseCnt, true,
	            		unknownPreds_[i]);

	            //cout<<endl;
	    	    //cout<<"getting false cnts ... "<<endl;
	    	    //state->getNumClauseGndingsWithUnknown(inferredFalseCnts[i], clauseCnt,
	    	    //                                        false, unknownPreds_[i]);
	    	    if (dldebug)
	    	    {
	    	       for (int clauseno = 0; clauseno < clauseCnt; clauseno++)
	    	       {
	    	          cout << clauseno << " : tc = " << inferredTrueCnts[i][clauseno] << endl;
	    	               //<< " ** fc = " << inferredFalseCnts[i][clauseno] << endl;
	    	       }
	    	    }
	          }
          }

          /* Append a new constraint */
          if (r == MSK_RES_OK)
        	  r = MSK_append(task,MSK_ACC_CON,1);

          /* Get index of new constraint */
          if (r == MSK_RES_OK)
        	  r = MSK_getnumcon(task,&numcon);

          /* Set bounds on new constraint */
          if (nonMarginRescaling) {
	          if (r == MSK_RES_OK)
	        	  r = MSK_putbound(task, MSK_ACC_CON, numcon-1, MSK_BK_LO, 1, +MSK_INFINITY);
          }
          else {
        	  if (r == MSK_RES_OK)
        	  	  r = MSK_putbound(task, MSK_ACC_CON, numcon-1, MSK_BK_LO, loss, +MSK_INFINITY);
          }

          /* Put new values in the A matrix */
          double tmp = 0;
          double tmp1 = 0;
          if (r == MSK_RES_OK) {
        	  MSKidxt subi[NUMVAR];
        	  MSKidxt subj[NUMVAR];
        	  MSKrealt cof[NUMVAR];
        	  //MSKidxt arowsub[NUMVAR];
        	  //double arowval[NUMVAR];
        	  if (idxTrans_ == NULL) {
				  for (int clauseno = 0; clauseno < numWeights; ++clauseno) {
					  //arowsub[clauseno] = clauseno;
					  //arowval[clauseno] =  (trainTrueCnts_[0][clauseno] - inferredTrueCnts[0][clauseno])/numOfExamples;
					  //tmp += arowval[clauseno]*weights[clauseno];
					  subi[clauseno] = numcon-1;
					  subj[clauseno] = clauseno;
					  //cof[clauseno] =  (trainTrueCnts_[0][clauseno] - inferredTrueCnts[0][clauseno])/numOfExamples;
					  cof[clauseno] = 0;
					  for (int domainId = 0; domainId < domainCnt_; ++domainId) {
						  const MLN* mln = inferences_[domainId]->getState()->getMLN();
						  const Clause* clause = mln->getClause(clauseno);
						  if (clause->isHardClause()) {
							  if (dldebug) {
								  cout << "Set the coefficient of this hard clause to 0. " << endl;
								  clause->printWithWtAndStrVar(cout,inferences_[domainId]->getState()->getDomain());
							  }
							  continue;
						  }
						  cof[clauseno] +=  (trainTrueCnts_[domainId][clauseno] - inferredTrueCnts[domainId][clauseno])/numOfExamples;
						  //cof[clauseno] +=  (trainTrueCnts_[domainId][clauseno] - inferredTrueCnts[domainId][clauseno]);
	  				  }
					  if (dldebug) {
						  cout << "cof[" <<clauseno << "]:" << cof[clauseno] << endl;
					  }
					  tmp1 += cof[clauseno];
					  tmp += cof[clauseno]*weights[clauseno];
				  }
        	  }
			  //arowsub[NUMVAR-1] = NUMVAR - 1;
			  //arowval[NUMVAR-1] = 1;
			  //r = MSK_putavec(task, MSK_ACC_CON, numcon-1, NUMVAR, arowsub, arowval);
			  subi[NUMVAR-1] = numcon-1;
			  subj[NUMVAR-1] = NUMVAR-1;
			  cof[NUMVAR-1] = 1;
			  r = MSK_putaijlist(task, NUMVAR, subi,subj,cof);
          }

          cout << "Current total feature count difference: " << tmp1 << endl;
          cout << "Current total weighted feature count difference: " << tmp << endl;

          if (nonMarginRescaling) {
        	  if (loss > 0)
        		  error = 1 - tmp;
        	  else
        		  error = 0;
          }
          else {
			  error = (loss - tmp);
          }
          cout << "Current error: " << error << endl;
		  cout << "Current stopping criteria: " << (slack + epsilon) << endl;

		  for (int i = 0; i < trainTrueCnts_.size(); i++)
          {
            delete[] inferredTrueCnts[i];
            //delete[] inferredFalseCnts[i];
          }

          // Reset counts.
          for (int i = 0; i < domainCnt_; i++)
              inferences_[i]->resetCnts();
          iter++ ;
      }
      while (error > (slack + epsilon) || (iter < minIter)) ;


      cout << endl << "Learned Weights : " << endl;
      int numZeros = 0;
      for (int w = 0; w < numWeights; w++)
      {
        if (weights[w] == 0) numZeros++;
        cout << w << ":" << weights[w] << endl;
      }

      cout << "Number of iterations: " << iter << endl;
      cout << "Number of non-zero weights: " << numWeights - numZeros << endl;
      resetDBs();
    } // end of learngWeightsCP



  void learnWeightsCPL1(double* const & weights, const int& numWeights,
    		  			const int& maxIter, const int& minIter, const double& maxSec,
    		  			const double& C, double epsilon, int lossFunction, double lossScale,
    		  			bool initWithLogOdds, bool maxMargin,bool ignoreUnknownQueryAtom, bool printLearnedWeightPerIter, bool nonRecursive)
      {
        Timer timer;
        double begSec = timer.time();

        cout << "1-norm max margin learning weights using cutting plane method... " << endl;

        double numOfExamples = 1;
        if (nonRecursive) {
		  numOfExamples = 0;
		  for (int i = 0; i < domainCnt_; i++)
		  {
			VariableState* state = inferences_[i]->getState();
			numOfExamples += state->getKnePredValues()->size();
		  }
        }

        cout << "Number of examples: " << numOfExamples << endl;
        cout << "Number of weights: " << numWeights << endl;
        memset(weights, 0, numWeights*sizeof(double));

        // Set the initial weight to the average log odds across domains/databases
        //if (initWithLogOdds)
      	//  setLogOddsWeights(weights, numWeights);

        double error = 1e+5;
        double slack = -1e+5;

        // Setup the LP solver
        int NUMVAR = numWeights*2 + 1;
        int NUMCON = maxIter;
        double        xx[NUMVAR];
        MSKenv_t      env;
        MSKtask_t     task;
        MSKrescodee   r;
        MSKintt numcon;


        /* Create the mosek environment. */
        r = MSK_makeenv(&env,NULL,NULL,NULL,NULL);

        /* Check whether the return code is ok. */
        if ( r==MSK_RES_OK )
        {
      	  /* Directs the log stream to the 'printstr' function. */
      	  MSK_linkfunctoenvstream(env,
                                MSK_STREAM_LOG,
                                NULL,
                                printstr);
        }

        /* Initialize the environment. */
        r = MSK_initenv(env);

        if ( r==MSK_RES_OK )
        {
      	  /* Create the optimization task. */
      	  r = MSK_maketask(env,NUMCON,NUMVAR,&task);

      	  /* Directs the log task stream to the 'printstr' function. */
      	  MSK_linkfunctotaskstream(task,MSK_STREAM_LOG,NULL,printstr);

      	  /* Give MOSEK an estimate of the size of the input data. This is done to increase the efficiency of inputting data, however it is optional.*/
      	  if (r == MSK_RES_OK)
      		  r = MSK_putmaxnumvar(task,NUMVAR);

      	  if (r == MSK_RES_OK)
      		  r = MSK_putmaxnumcon(task,NUMCON);

      	  /* Append the variables. */
      	  if (r == MSK_RES_OK)
      		  r = MSK_append(task,MSK_ACC_VAR,NUMVAR);

      	  /* Put variable bound */
      	  // All variables are >= 0.
      	  if (r == MSK_RES_OK) {
      		  for(int j=0; j < NUMVAR; ++j) {
      			  r = MSK_putbound(task,MSK_ACC_VAR,j,MSK_BK_LO,0,+MSK_INFINITY);
      		  }
      	  }

      	  /* Put C */
      	  if (r == MSK_RES_OK)
      		  r = MSK_putcfix(task, 0.0);

      	  /* Put c */
      	  if (r == MSK_RES_OK) {
      		  for(int j=0; j < NUMVAR-1; ++j) {
      			  r = MSK_putcj(task,j,1);
      		  }
      		  r = MSK_putcj(task,NUMVAR-1,C);
      	  }

	  	  if (r == MSK_RES_OK) {
	  		  MSK_putobjsense(task,MSK_OBJECTIVE_SENSE_MINIMIZE);
	  	  }

        }

        int iter = 1;
        do {
          if (iter > maxIter) break;
      	  cout << endl << "Iteration " << iter << " : " << endl << endl;
      	  double totalsec = timer.time() - begSec;
            int hour = (int)totalsec/3600;
            int min = (int)(totalsec - 3600*hour)/60;
            int sec = (int)(totalsec - 3600*hour - 60*min);

              // Print time so far
            cout << "Elapsed time: " << totalsec << "s";
            if (hour > 0)
              cout << " (" << hour << "h " << min << "m " << sec << "s)";
            else if (min > 0)
              cout << " (" << min << "m " << sec << "s)";
            cout << endl;

            if (maxSec > 0 && totalsec > maxSec)
            {
              cout << "Time limit exceeded.  Stopping learning." << endl;
              break;
            }

            if (iter > 1) {
          	  //if (iter > 2) break;
          	  cout << "Learning the weights ... " << endl;
          	  if (dldebug) {
  		    	  r = MSKAPI MSK_printdata (
  		    	      task, //MSKtask_t task,
  		    	      MSK_STREAM_LOG, //MSKstreamtypee whichstream,
  		    	      0, //MSKidxt firsti,
  		    	      numcon, //MSKidxt lasti,
  		    	      0, //MSKidxt firstj,
  		    	      NUMVAR, //MSKidxt lastj,
  		    	      0, //MSKidxt firstk,
  		    	      0, //MSKidxt lastk,
  		    	      1, //MSKintt c,
  		    	      0, //MSKintt qo,
  		    	      1, //MSKintt a,
  		    	      0, //MSKintt qc,
  		    	      1, //MSKintt bc,
  		    	      0, //MSKintt bx,
  		    	      0, //MSKintt vartype,
  		    	      0 //MSKintt cones);
  		    	      );
          	  }

  		      // Solve the QP problem
  		      if ( r==MSK_RES_OK ) {
  		    	  cout << "Running Mosek to solve the current LP problem ... " << endl;
  		    	  r = MSK_optimize(task);
  		    	  cout << "Return code: " << r << endl;
  		      }


			  cout << "Getting the solution for the current LP problem... " << endl;
			  r = MSK_getsolutionslice(task,
								   MSK_SOL_BAS,
								   //MSK_SOL_ITR,
								   MSK_SOL_ITEM_XX,
								   0,
								   NUMVAR,
								   xx);
  		          //printf("Primal solution\n");
  		          //for(j=0; j<NUMVAR; ++j)
  		            //printf("x[%d]: %e\n",j,xx[j]);
  		      if ( r==MSK_RES_OK )
  		      {
  		          bool converged = true;
  		          int numOfNonZeroWts = 0;
  		          for (int w = 0; w < numWeights; w++)
  		          {
  		        	  if (weights[w] != (xx[w] - xx[w+numWeights])) {
  		        		  weights[w] = xx[w] - xx[w+numWeights];
  		        		  converged = false;
  		        	  }
  		        	  if (weights[w])
  		        		  numOfNonZeroWts++;
  		        	  if (dldebug)
  		        		  cout << w << ":" << weights[w] << endl;
  		          }

  		          cout << "Number of non-zero weights: " << numOfNonZeroWts << endl;
  		          if (slack != xx[NUMVAR-1]) {
   		        	  slack = xx[NUMVAR-1];
   		          }
  		          cout << "Current slack value: " << slack << endl;
  		          if (converged) {
  		        	  cout << "Converged!" << endl;
  		        	  break;
  		          }
  		      }
  		      else {
				cout << "Encounter error when getting the solution of the current LP problem." << endl;
				cout << "Error code: " << r << endl;
				break;
  		      }
            }

            if (printLearnedWeightPerIter) {
			  cout << endl << "Learned weights iteration " << iter << ":" << endl;
			  for (int w = 0; w < numWeights; w++)
			  {
				 cout << w << ":" << weights[w] << endl;
			  }
            }

            cout << "Setting up weights ... " << endl;
            // Set the weights and run inference
            setMLNWeights(weights);

            cout << "Running inference ..." << endl;
            infer();
            cout << "Done with inference" << endl;

            double loss = calculateError(lossFunction,ignoreUnknownQueryAtom)/numOfExamples;
            cout << "Current loss: " << loss << endl;
            loss = loss*lossScale;

            Array<double*> inferredTrueCnts;
            //Array<double*> inferredFalseCnts;

            inferredTrueCnts.growToSize(domainCnt_);
            //inferredFalseCnts.growToSize(domainCnt_);

            if (dldebug) cout << "Computing inferred counts... " << endl;
            for (int i = 0; i < domainCnt_; i++)
            {
              if (dldebug) cout << "Domain " << i << endl;
              int clauseCnt = clauseCntPerDomain_[i];
              if (dldebug) cout << "Clause count: " << clauseCnt << endl;

              inferredTrueCnts[i] = new double[clauseCnt];
              //inferredFalseCnts[i] = new double[clauseCnt];

              cout<<"getting true cnts ... "<<endl;
              VariableState* state = inferences_[i]->getState();
              state->getNumClauseGndingsWithUnknown(inferredTrueCnts[i], clauseCnt, true,
            		  unknownPreds_[i]);

              //cout<<endl;
		  	  //cout<<"getting false cnts ... "<<endl;
		  	  //state->getNumClauseGndingsWithUnknown(inferredFalseCnts[i], clauseCnt,
		  	  //                                         false, unknownPreds_[i]);
		  	  if (dldebug)
		  	  {
	  	         for (int clauseno = 0; clauseno < clauseCnt; clauseno++)
	  	         {
	  	        	 cout << clauseno << " : tc = " << inferredTrueCnts[i][clauseno] << endl;
	  	             //  << " ** fc = " << inferredFalseCnts[i][clauseno] << endl;
	  	         }
		  	  }
            }

            /* Append a new constraint */
            if (r == MSK_RES_OK)
          	  r = MSK_append(task,MSK_ACC_CON,1);

            /* Get index of new constraint */
            if (r == MSK_RES_OK)
          	  r = MSK_getnumcon(task,&numcon);

            if (maxMargin) {
	          if (r == MSK_RES_OK)
	        	  r = MSK_putbound(task, MSK_ACC_CON, numcon-1, MSK_BK_LO, 1, +MSK_INFINITY);
            }
            else {
        	  if (r == MSK_RES_OK)
        	  	  r = MSK_putbound(task, MSK_ACC_CON, numcon-1, MSK_BK_LO, loss, +MSK_INFINITY);
            }

            /* Put new values in the A matrix */
            double tmp = 0;
            double tmp1 = 0;
            if (r == MSK_RES_OK) {
          	  MSKidxt subi[NUMVAR];
          	  MSKidxt subj[NUMVAR];
          	  MSKrealt cof[NUMVAR];
          	  //MSKidxt arowsub[NUMVAR];
          	  //double arowval[NUMVAR];

  			  for (int clauseno = 0; clauseno < numWeights; ++clauseno) {
  				  //arowsub[clauseno] = clauseno;
  				  //arowval[clauseno] =  (trainTrueCnts_[0][clauseno] - inferredTrueCnts[0][clauseno])/numOfExamples;
  				  //tmp += arowval[clauseno]*weights[clauseno];
  				  subi[clauseno] = numcon-1; // u_p
  				  subi[clauseno + numWeights] = numcon-1; // v_p
  				  subj[clauseno] = clauseno; // u_p
  				  subj[clauseno + numWeights] = clauseno + numWeights; //v_p
  				  cof[clauseno] = 0;
  				  for (int domainId = 0; domainId < domainCnt_; ++domainId) {
  					  const MLN* mln = inferences_[domainId]->getState()->getMLN();
  					  const Clause* clause = mln->getClause(clauseno);
  					  if (clause->isHardClause()) {
						  if (dldebug) {
							  cout << "Ignore this hard clause: " << endl;
							  clause->printWithWtAndStrVar(cout,inferences_[domainId]->getState()->getDomain());
						  }
						  continue;
					  }
  					  cof[clauseno] +=  (trainTrueCnts_[domainId][clauseno] - inferredTrueCnts[domainId][clauseno])/numOfExamples;
				  }
  				   // u_p
  				  cof[clauseno + numWeights] = - cof[clauseno]; // v_p
  				  if (dldebug) {
  					  cout << "cof[" <<clauseno << "]:" << cof[clauseno] << endl;
  					  cout << "cof[" <<clauseno + numWeights << "]:" << cof[clauseno + numWeights] << endl;
  				  }
  				  tmp += cof[clauseno]*weights[clauseno];
  				  tmp1 += cof[clauseno];
  			   }
  			  //arowsub[NUMVAR-1] = NUMVAR - 1;
  			  //arowval[NUMVAR-1] = 1;
  			  //r = MSK_putavec(task, MSK_ACC_CON, numcon-1, NUMVAR, arowsub, arowval);
  			  subi[NUMVAR-1] = numcon-1;
  			  subj[NUMVAR-1] = NUMVAR-1;
  			  cof[NUMVAR-1] = 1;
  			  r = MSK_putaijlist(task, NUMVAR, subi,subj,cof);
            }

          cout << "Current total feature count difference: " << tmp1 << endl;
          cout << "Current total weighted feature count difference: " << tmp << endl;

  		  error = (loss - tmp);
  		  cout << "Current error: " << error << endl;
  		  cout << "Current stopping criteria: " << (slack + epsilon) << endl;

  		  for (int i = 0; i < trainTrueCnts_.size(); i++)
            {
              delete[] inferredTrueCnts[i];
              //delete[] inferredFalseCnts[i];
            }

            // Reset counts.
            for (int i = 0; i < domainCnt_; i++)
                inferences_[i]->resetCnts();
            iter++ ;
        }
        while (error > (slack + epsilon) || (iter < minIter)) ;

        cout << endl << "Learned Weights : " << endl;
        int numZeros = 0;
        for (int w = 0; w < numWeights; w++)
        {
          if (weights[w] == 0) numZeros++;
          cout << w << ":" << weights[w] << endl;
        }

        cout << "Number of iterations: " << iter << endl;
        cout << "Number of non-zero weights: " << numWeights - numZeros << endl;
        resetDBs();
      } // end of learngWeightsCPL1


 private:

  /**
   * Resets the values of non-evidence predicates as they were before learning.
   */
  void resetDBs()
  {
    if (!lazyInference_)
    {
      for (int i = 0; i < domainCnt_; i++)
      {
        VariableState* state = inferences_[i]->getState();
        Database* db = state->getDomain()->getDB();
          // Change known NE to original values
        const GroundPredicateHashArray* knePreds = state->getKnePreds();
        const Array<TruthValue>* knePredValues = state->getKnePredValues();
        db->setValuesToGivenValues(knePreds, knePredValues);
          // Set unknown NE back to UKNOWN
        const GroundPredicateHashArray* unePreds = state->getUnePreds();
        for (int predno = 0; predno < unePreds->size(); predno++)
          db->setValue((*unePreds)[predno], UNKNOWN);
      }
    }
  }

  /**
   * Assign true to the elements in the relevantClauses_ bool array
   * corresponding to indices of clauses which would be relevant for list of
   * non-evidence predicates.
   */
  void findRelevantClauses(const StringHashArray& nonEvidPredNames)
  {
    for (int d = 0; d < domainCnt_; d++)
    {
      if (dldebug) cout << "Domain " << d << endl;
      int clauseCnt = clauseCntPerDomain_[d];
      if (dldebug) cout << "Clause count: " << clauseCnt << endl;
      Array<bool>& relevantClauses = relevantClausesPerDomain_[d];
      relevantClauses.growToSize(clauseCnt);
      memset((bool*)relevantClauses.getItems(), false,
             relevantClauses.size()*sizeof(bool));
      const Domain* domain = inferences_[d]->getState()->getDomain();
      const MLN* mln = inferences_[d]->getState()->getMLN();

      const Array<IndexClause*>* indclauses;
      const Clause* clause;
      int predid, clauseid;
      for (int i = 0; i < nonEvidPredNames.size(); i++)
      {
        predid = domain->getPredicateId(nonEvidPredNames[i].c_str());
        //cout << "finding the relevant clauses for predid = " << predid
        //     << " in domain " << d << endl;
        indclauses = mln->getClausesContainingPred(predid);
        if (indclauses)
        {
          for (int j = 0; j < indclauses->size(); j++)
          {
            clause = (*indclauses)[j]->clause;
            clauseid = mln->findClauseIdx(clause);

            // If clause is external to this mln, then it stays irrelevant
            if (!mln->isExternalClause(clauseid)) relevantClauses[clauseid] = true;
          }
        }
      }
    }
  }


  void findRelevantClausesFormulas()
  {
    if (idxTrans_ == NULL)
    {
      Array<bool>& relevantClauses = relevantClausesPerDomain_[0];
      relevantClausesFormulas_.growToSize(relevantClauses.size());
      for (int i = 0; i < relevantClauses.size(); i++)
        relevantClausesFormulas_[i] = relevantClauses[i];
    }
    else
    {
      idxTrans_->setRelevantClausesFormulas(relevantClausesFormulas_,
                                            relevantClausesPerDomain_[0]);
      cout << "Relevant clauses/formulas:" << endl;
      idxTrans_->printRelevantClausesFormulas(cout, relevantClausesFormulas_);
      cout << endl;
    }
  }


  /**
   * Calculate true/false/unknown counts for all clauses for the given domain.
   *
   * @param trueCnt Number of true groundings for each clause is stored here.
   * @param falseCnt Number of false groundings for each clause is stored here.
   * @param domainIdx Index of domain where the groundings are counted.
   * @param hasUnknownPreds If true, the domain has predicates with unknown
   * truth values. Otherwise it contains only predicates with known values.
   */
  void calculateCounts(Array<double>& trueCnt, Array<double>& falseCnt,
                       const int& domainIdx, const bool& hasUnknownPreds)
  {
    Clause* clause;
    double tmpUnknownCnt;
    int clauseCnt = clauseCntPerDomain_[domainIdx];
    Array<bool>& relevantClauses = relevantClausesPerDomain_[domainIdx];
    const MLN* mln = inferences_[domainIdx]->getState()->getMLN();
    const Domain* domain = inferences_[domainIdx]->getState()->getDomain();

    for (int clauseno = 0; clauseno < clauseCnt; clauseno++)
    {
      if (!relevantClauses[clauseno])
      {
        continue;
        //cout << "\n\nthis is an irrelevant clause.." << endl;
      }
      clause = (Clause*) mln->getClause(clauseno);
      clause->getNumTrueFalseUnknownGroundings(domain, domain->getDB(),
                                               hasUnknownPreds,
                                               trueCnt[clauseno],
                                               falseCnt[clauseno],
                                               tmpUnknownCnt);
      assert(hasUnknownPreds || (tmpUnknownCnt==0));
    }
  }

  /**
   * Initializes the weights of the clauses. Assumption is that the inferences_
   * (and their states) have been constructed.
   *
   * @param nonEvidPredNames Names of the non-evidence predicate names in the
   * domain.
   */
  void initializeWts(const StringHashArray& nonEvidPredNames)
  {
    cout << "Initializing weights ..." << endl;

    bool hasUnknownPreds;

    Array<Predicate*> gpreds;
    Array<Predicate*> ppreds;
    Array<TruthValue> gpredValues;
    Array<TruthValue> tmpValues;

    if (!lazyInference_)
    { // Eager inference
      trainTrueCnts_.growToSize(domainCnt_);
      trainFalseCnts_.growToSize(domainCnt_);
    }

    for (int i = 0; i < domainCnt_; i++)
    {
      if (dldebug) cout << "Domain " << i << endl;
      int clauseCnt = clauseCntPerDomain_[i];
      VariableState* state = inferences_[i]->getState();
      Domain* domain = (Domain*)state->getDomain();

      if (lazyInference_)
      {
        domain->getDB()->setPerformingInference(false);

        //cout << endl << "Getting the counts for the domain " << i << endl;
        gpreds.clear();
        gpredValues.clear();
        tmpValues.clear();
        for (int predno = 0; predno < nonEvidPredNames.size(); predno++)
        {
          ppreds.clear();
          int predid = domain->getPredicateId(nonEvidPredNames[predno].c_str());
          Predicate::createAllGroundings(predid, domain, ppreds);
          gpreds.append(ppreds);
        }

        domain->getDB()->alterTruthValue(&gpreds, UNKNOWN, FALSE, &gpredValues);

        hasUnknownPreds = false;

        Array<double>& trueCnt = totalTrueCnts_[i];
        Array<double>& falseCnt = totalFalseCnts_[i];
        trueCnt.growToSize(clauseCnt);
        falseCnt.growToSize(clauseCnt);
        calculateCounts(trueCnt, falseCnt, i, hasUnknownPreds);

        //cout << "got the total counts..\n\n\n" << endl;

        hasUnknownPreds = true;

        domain->getDB()->setValuesToUnknown(&gpreds, &tmpValues);

        Array<double>& dTrueCnt = defaultTrueCnts_[i];
        Array<double>& dFalseCnt = defaultFalseCnts_[i];
        dTrueCnt.growToSize(clauseCnt);
        dFalseCnt.growToSize(clauseCnt);
        calculateCounts(dTrueCnt, dFalseCnt, i, hasUnknownPreds);

        for (int predno = 0; predno < gpreds.size(); predno++)
          delete gpreds[predno];

        domain->getDB()->setPerformingInference(true);
      }
      else
      { // Eager inference
        const GroundPredicateHashArray* unePreds = state->getUnePreds();
        const GroundPredicateHashArray* knePreds = state->getKnePreds();

        trainTrueCnts_[i] = new double[clauseCnt];
        trainFalseCnts_[i] = new double[clauseCnt];

        if (dldebug)
        {
          cout << "Unknown non-evid preds: " << unePreds->size() << endl;
          cout << "Known non-evid preds: " << knePreds->size() << endl;
          /*
          for (int i = 0; i < knePreds->size(); ++i) {
    	      GroundPredicate* gndPred = (*knePreds)[i];
    	      gndPred->print(cout,state->getDomain());
          	  cout << " " << (*state->getKnePredValues())[i] << endl;
      	  }
      	  */
        }
        int totalPreds = unePreds->size() + knePreds->size();
          // Used to store gnd preds to be ignored in the count because they are
          // UNKNOWN

        unknownPreds_[i] = new Array<bool>;
        unknownPreds_[i]->growToSize(totalPreds, false);

        for (int predno = 0; predno < totalPreds; predno++)
        {
          GroundPredicate* p;
          if (predno < unePreds->size())
            p = (*unePreds)[predno];
          else
            p = (*knePreds)[predno - unePreds->size()];
          TruthValue tv = state->getDomain()->getDB()->getValue(p);

          //assert(tv != UNKNOWN);
          //bool activate = true;
          bool activate = false;
          if (tv == TRUE)
          {
            state->setValueOfAtom(predno + 1, true, activate, -1);
            p->setTruthValue(true);
          }
          else
          {
            state->setValueOfAtom(predno + 1, false, activate, -1);
            p->setTruthValue(false);
              // Can have unknown truth values when using EM. We want to ignore
              // these when performing the counts
            if (tv == UNKNOWN)
            {
              (*unknownPreds_[i])[predno] = true;
            }
          }
        }

        state->initMakeBreakCostWatch();
        //cout<<"getting true cnts => "<<endl;
        state->getNumClauseGndingsWithUnknown(trainTrueCnts_[i], clauseCnt, true,
                                              unknownPreds_[i]);
        //cout<<endl;
        //cout<<"getting false cnts => "<<endl;
        state->getNumClauseGndingsWithUnknown(trainFalseCnts_[i], clauseCnt,
                                              false, unknownPreds_[i]);

        if (dldebug)
        {
          for (int clauseno = 0; clauseno < clauseCnt; clauseno++)
          {
            cout << clauseno << " : tc = " << trainTrueCnts_[i][clauseno]
                 << " ** fc = " << trainFalseCnts_[i][clauseno] << endl;
          }
        }
      }
    }

    double tc,fc;
    int nonEvidPreds = 0;
    cout << "List of CNF Clauses : " << endl;
    for (int clauseno = 0; clauseno < clauseCntPerDomain_[0]; clauseno++)
    {
      tc = 0.0; fc = 0.0;
      for (int i = 0; i < domainCnt_; i++)
      {
        Domain* domain = (Domain*)inferences_[i]->getState()->getDomain();
        Array<bool>& relevantClauses = relevantClausesPerDomain_[i];
        //Array<double>& logOdds = logOddsPerDomain_[i];

        if (!relevantClauses[clauseno])
        {
          domain->setNumTrueNonEvidGndings(clauseno, 0);
          domain->setNumFalseNonEvidGndings(clauseno, 0);
          //logOdds[clauseno] = 0.0;
          continue;
        }

        cout << clauseno << ":";
        const Clause* clause =
          inferences_[i]->getState()->getMLN()->getClause(clauseno);
        clause->print(cout, inferences_[0]->getState()->getDomain());
        cout << endl;

        if (lazyInference_)
        {
          tc += totalTrueCnts_[i][clauseno] - defaultTrueCnts_[i][clauseno];
          fc += totalFalseCnts_[i][clauseno] - defaultFalseCnts_[i][clauseno];
        }
        else
        {
          tc += trainTrueCnts_[i][clauseno];
          fc += trainFalseCnts_[i][clauseno];
        }

        if (dldebug)
          cout << clauseno << " : tc = " << tc << " ** fc = "<< fc <<endl;

        domain->setNumTrueNonEvidGndings(clauseno, tc);
        domain->setNumFalseNonEvidGndings(clauseno, fc);

        for (int i = 0; i < clause->getNumPredicates(); i++)
        {
          const char* predName = clause->getPredicate(i)->getTemplate()->getName();
          if (nonEvidPredNames.contains(predName))
            nonEvidPreds++;
        }
      }

      double weight = 0.0;
      double totalCnt = tc + fc;

      if (totalCnt == 0 || nonEvidPreds == 0)
      {
        //cout << "NOTE: Total count is 0 for clause " << clauseno << endl;
        weight = EPSILON;
      }
      else
      {
        if (fc == 0.0)
          fc = 0.00001;
        if (tc == 0.0)
          tc = 0.00001;

        double priorodds = (pow(2.0, nonEvidPreds) - 1.0)/1.0;
        weight = log(tc/fc) - log(priorodds);
      }

      /*
      for (int i = 0; i < domainCnt_; i++)
      {
      	Array<double>& logOdds = logOddsPerDomain_[i];
        logOdds[clauseno] = weight;
      }
      */
    }
  }


  /**
   * Runs inference using the current set of parameters.
   */
  void infer()
  {
    for (int i = 0; i < domainCnt_; i++)
    {
      cout << endl << "Running inference for domain " << i << " ..." << endl;
      inferences_[i]->reinit();
      VariableState* state = inferences_[i]->getState();
      state->setGndClausesWtsToSumOfParentWts();
      // MWS: Search is started from state at end of last iteration
      state->init();
      inferences_[i]->infer();
      inferences_[i]->saveInferredResultsToDB();
      state->saveLowStateToGndPreds();
    }
  }


  int calculateError(int lossFunction, bool ignoreUnknownQueryAtom) {
	  cout << "Computing infererred error ... " << endl;
	  int totalError = 0;
	  int totalExamples = 0;
	  int totalNumFalseTruePrediction = 0;
	  int totalLoss = 0;
	  for (int domainId = 0; domainId < domainCnt_; domainId++)
	  {
		  int numExamples = 0;
		  int error = 0;
		  VariableState* state = inferences_[domainId]->getState();
		  Database* db = state->getDomain()->getDB();

		  const GroundPredicateHashArray* knePreds = state->getKnePreds();
		  const Array<TruthValue>* knePredValues = state->getKnePredValues();
		  numExamples += knePredValues->size();
		  for (int i = 0; i < knePreds->size(); ++i) {
		      GroundPredicate* gndPred = (*knePreds)[i];
		      //bool val = gndPred->getTruthValue();
		      TruthValue val = db->getValue(gndPred);
		      if ((val == FALSE) && ((*knePredValues)[i] == TRUE)) {
		    	  totalNumFalseTruePrediction++;
		      }
		      if (((val == TRUE) && ((*knePredValues)[i] == FALSE)) ||
		          ((val == FALSE) && ((*knePredValues)[i] == TRUE)))
		      {
		    	if (dldebug) {
		    		gndPred->print(cout,state->getDomain());
		    		cout << " " << gndPred->getTruthValue() << endl;
		    	}
		    	error++;
		      }
		  }
		  if (!ignoreUnknownQueryAtom) {
			  const GroundPredicateHashArray* unePreds = state->getUnePreds();
			  numExamples += unePreds->size();
			  for (int i = 0; i < unePreds->size(); ++i) {
				  GroundPredicate* gndPred = (*unePreds)[i];
				  //bool val = gndPred->getTruthValue();
				  TruthValue val = db->getValue(gndPred);
				  if (val == TRUE)
				  {
					if (dldebug) {
						gndPred->print(cout,state->getDomain());
						cout << " " << gndPred->getTruthValue() << endl;
					}
					error++;
				  }
			  }
		  }
  		  totalExamples += numExamples;
  		  totalError += error;
		  cout << "Inferred error for domain " << domainId << " : " << error << "/" << numExamples << endl;
	  }

	  cout << "Total inferred error: " << totalError << "/" << totalExamples << endl;
	  switch (lossFunction) {
	  	case HAMMING:
	  		totalLoss = totalError;
	  		cout << "Using misclassifed loss..." << endl;
	  		break;
	  	case F1:
	  		totalLoss = totalError + totalNumFalseTruePrediction;
	  		cout << "Using (1 - F1) loss..." << endl;
	  		break;
	  }

	  return totalLoss;
  }

  double l2NormSquare(double* const & v, const int& size) {
	  double result = 0;
	  for (int i = 0; i < size; ++i) {
		  result += v[i]*v[i];
	  }
	  return result;
  }

  double l1Norm(double* const & v, const int& size) {
  	  double result = 0;
  	  for (int i = 0; i < size; ++i) {
  		  result += abs(v[i]);
  	  }
  	  return result;
  }

  /**
   * Infers values for predicates with unknown truth values and uses these
   * values to compute the training counts.
   */
  void fillInMissingValues()
  {
    assert(withEM_);
    cout << "Filling in missing data ..." << endl;
      // Get values of initial unknown preds by producing MAP state of
      // unknown preds given known evidence and non-evidence preds (VPEM)
    Array<Array<TruthValue> > ueValues;
    ueValues.growToSize(domainCnt_);
    for (int i = 0; i < domainCnt_; i++)
    {
      VariableState* state = inferences_[i]->getState();
      const Domain* domain = state->getDomain();
      const GroundPredicateHashArray* knePreds = state->getKnePreds();
      const Array<TruthValue>* knePredValues = state->getKnePredValues();

        // Mark known non-evidence preds as evidence
      domain->getDB()->setValuesToGivenValues(knePreds, knePredValues);

        // Infer missing values
      state->setGndClausesWtsToSumOfParentWts();
        // MWS: Search is started from state at end of last iteration
      state->init();
      inferences_[i]->infer();
      state->saveLowStateToGndPreds();

      if (dldebug)
      {
        cout << "Inferred following values: " << endl;
        inferences_[i]->printProbabilities(cout);
      }

        // Compute counts
      int clauseCnt = clauseCntPerDomain_[i];
      state->initMakeBreakCostWatch();
      //cout<<"getting true cnts => "<<endl;
      const Array<double>* clauseTrueCnts =
        inferences_[i]->getClauseTrueCnts();
      assert(clauseTrueCnts->size() == clauseCnt);
      int numSamples = inferences_[i]->getNumSamples();
      for (int j = 0; j < clauseCnt; j++)
        trainTrueCnts_[i][j] = (*clauseTrueCnts)[j]/numSamples;

        // Set evidence values back
      //assert(uePreds.size() == ueValues[i].size());
      //domain->getDB()->setValuesToGivenValues(&uePreds, &ueValues[i]);
        // Set non-evidence values to unknown
      Array<TruthValue> tmpValues;
      tmpValues.growToSize(knePreds->size());
      domain->getDB()->setValuesToUnknown(knePreds, &tmpValues);
    }
    cout << "Done filling in missing data" << endl;
  }

#if 0
  // This was used by the statistical significance convergence test,
  // to see if our counts could be drawn from the same distribution
  // as the true counts.

  void getCountsForDomain(int* const & clauseTrainCnts,
          int* const & clauseTrainTotal, int* const & clauseInferredCnts,
          int* const & clauseInferredTotal, int domainIdx)
  {
    Array<bool>& relevantClauses = relevantClausesPerDomain_[domainIdx];
    int clauseCnt = clauseCntPerDomain_[domainIdx];
    double* trainCnts = NULL;
    double* inferredCnts = NULL;
    Array<double>& totalTrueCnts = totalTrueCnts_[domainIdx];
    //Array<double>& totalFalseCnts = totalFalseCnts_[domainIdx];
    Array<double>& defaultTrueCnts = defaultTrueCnts_[domainIdx];
    const MLN* mln = inferences_[domainIdx]->getState()->getMLN();
    const Domain* domain = inferences_[domainIdx]->getState()->getDomain();

    memset(clauseTrainCnts, 0, clauseCnt*sizeof(double));
    memset(clauseInferredCnts, 0, clauseCnt*sizeof(double));
    memset(clauseTrainTotal, 0, clauseCnt*sizeof(double));
    memset(clauseInferredTotal, 0, clauseCnt*sizeof(double));

    if (!lazyInference_)
    {
      if (!inferredCnts) inferredCnts = new double[clauseCnt];

      const Array<double>* clauseTrueCnts =
        inferences_[domainIdx]->getClauseTrueCnts();
      assert(clauseTrueCnts->size() == clauseCnt);
      for (int i = 0; i < clauseCnt; i++)
        inferredCnts[i] = (*clauseTrueCnts)[i];

      trainCnts = trainTrueCnts_[domainIdx];
    }
      //loop over all the training examples
    //cout << "\t\ttrain count\t\t\t\tinferred count" << endl << endl;
    for (int clauseno = 0; clauseno < clauseCnt; clauseno++)
    {
      if (!relevantClauses[clauseno]) continue;

      // Compute total groundings
      int totalGndings = (int)(trainFalseCnts_[domainIdx][clauseno]
              + trainTrueCnts_[domainIdx][clauseno]);
      clauseTrainTotal[clauseno] += totalGndings;
      clauseInferredTotal[clauseno] += totalGndings *
          inferences_[domainIdx]->getNumSamples();

      if (lazyInference_)
      {
      	Clause* clause = (Clause*) mln->getClause(clauseno);

      	double trainCnt = totalTrueCnts[clauseno];
      	double inferredCnt =
          clause->getNumTrueGroundings(domain, domain->getDB(), false);
      	trainCnt -= defaultTrueCnts[clauseno];
      	inferredCnt -= defaultTrueCnts[clauseno];
      	clauseTrainCnts[clauseno] += (int)trainCnt;
      	clauseInferredCnts[clauseno] += (int)inferredCnt;
      }
      else
      {
        clauseTrainCnts[clauseno] += (int)trainCnts[clauseno];
        clauseInferredCnts[clauseno] += (int)inferredCnts[clauseno];
      }
      //cout << clauseno << ":\t\t" <<trainCnt<<"\t\t\t\t"<<inferredCnt<<endl;
    }

    delete[] inferredCnts;
  }
#endif

public:
	// Different learing rates
	// constant step size
    const static int CS = 1;
    // diminishing step size
    const static int DS = 2;
    // combination of two above
    const static int CBS = 3;
    const static int SUBG = 1;
    const static int CP = 2;

    // Different loss function
    const static int HAMMING = 1; // Number of misclassified atoms
    const static int F1 = 2;


 private:
  int domainCnt_;
  //Array<Array<double> > logOddsPerDomain_;
  Array<int> clauseCntPerDomain_;

	// Used in lazy version
  Array<Array<double> > totalTrueCnts_;
  Array<Array<double> > totalFalseCnts_;
  Array<Array<double> > defaultTrueCnts_;
  Array<Array<double> > defaultFalseCnts_;

  Array<Array<bool> > relevantClausesPerDomain_;
  Array<bool> relevantClausesFormulas_;
  Array<Array<bool> *> unknownPreds_;

	// Used to compute cnts from mrf
  Array<double*> trainTrueCnts_;
  Array<double*> trainFalseCnts_;

  bool usePrior_;
  double precision_;

  IndexTranslator* idxTrans_; //not owned by object; don't delete

  bool lazyInference_;
  bool isQueryEvidence_;
  int maxBacktracks_;
  int backtrackCount_;

  Array<Inference*> inferences_;

    // Using EM to fill in missing values?
  bool withEM_;

  bool dldebug;
};


#endif
