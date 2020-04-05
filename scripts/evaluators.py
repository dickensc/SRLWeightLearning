from sklearn.metrics import mean_squared_error
from sklearn.metrics import accuracy_score
from sklearn.metrics import f1_score
from sklearn.metrics import roc_auc_score


def evaluate_mse(predicted_df, truth_df, observed_df):
    # Join predicted_df and truth_df on the arguments 
    experiment_frame = truth_df.join(predicted_df, how="left",
                                     lsuffix='_truth', rsuffix='_predicted')
    
    return mean_squared_error(experiment_frame.val_truth, experiment_frame.val_predicted)


def evaluate_accuracy(predicted_df, truth_df, observed_df):
    # get predicted categories, that is the predictions that represent 
    # the best categorical assignment for the first arg
    # consider overlap between observed and truths
    complete_predictions = observed_df.append(predicted_df)
    predicted_categories_df = complete_predictions.groupby(level=0).transform(lambda x: x.index.isin(x.iloc[[x.argmax()]].index))
    
    # boolean for truth df type
    truth_df = (truth_df == 1)
    
    # Join predicted_df and truth_df on the arguments 
    experiment_frame = truth_df.join(predicted_categories_df, how="inner", 
                                     lsuffix='_truth', rsuffix='_predicted').fillna(False)
    
    return accuracy_score(experiment_frame.val_truth, experiment_frame.val_predicted)


def evaluate_f1(predicted_df, truth_df, observed_df, threshold=0.5):
    # consider overlap between observed and truths 
    complete_predictions = observed_df.append(predicted_df)
    
    # Join predicted_df and truth_df on the arguments
    # if there are truth in the observed then evaluating on observed 
    # predicates.
    experiment_frame = truth_df.join(complete_predictions, how="inner", 
                                     lsuffix='_truth', rsuffix='_predicted')
    print("experiment_frame len: {}".format(len(experiment_frame)))
    
    rounded_predictions = experiment_frame.val_predicted > threshold
    rounded_truths = experiment_frame.val_truth > threshold

    return f1_score(rounded_truths, rounded_predictions, pos_label=True)


def evaluate_roc_auc_score(predicted_df, truth_df, observed_df, threshold=0.5):
    # Join predicted_df and truth_df on the arguments 
    experiment_frame = truth_df.join(predicted_df, how="left", 
                                     lsuffix='_truth', rsuffix='_predicted')
    print("experiment_frame len: {}".format(len(experiment_frame)))
    relevant = experiment_frame.val_truth > threshold
    return roc_auc_score(relevant, experiment_frame.val_predicted)