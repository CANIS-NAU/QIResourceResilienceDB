import firebase_admin
from firebase_admin import credentials, firestore

#set credentials
cred = credentials.Certificate("./.secret/sunrise-dev.json")
#initialize firebase
firebase_admin.initialize_app(cred)

COST_MAPPING = {
    'Free': 'free', 
    'Covered by insurance': 'insurance_covered',
    'Covered by insurance with copay': 'insurance_copay',
    'Sliding scale (income-based)': 'income_scale',
    'Pay what you can/donation-based': 'donation', 
    'Payment plans available': 'payment_plan', 
    'Subscription': 'subscription', 
    'One-time fee': 'fee', 
    'Free trial period': 'free_trial', 
    'Fees associated': 'fee'
}

#function definition


def modify_resource():
    """Converts current cost field of each resource to list of normalized strings"""

    # init variables
    db = firestore.client()
    resources = db.collection("resources")

    updated_count = 0

    # iterate through documents
    for doc in resources.stream():

        update_data = {"cost" : []}
        values_changed = False

        # convert to py dictionary
        data = doc.to_dict()

        # get current value
        current_value = data.get("cost", "")

        # convert all values to list
        if type(current_value) != list:
            current_value = [current_value]
    
        # loop through cost field
        for entry in current_value:

            if entry in COST_MAPPING.values(): # is already correct
                # append unchanged
                update_data["cost"].append(entry)

            elif entry in COST_MAPPING.keys():
                # append updated string to dictionary entry
                update_data["cost"].append( COST_MAPPING[entry] )
                values_changed = True

            else:
                print(f"Error, unrecognized cost value. Document: {doc.id}")

        # check if changes need to be applied, double check not empty
        if values_changed and update_data["cost"]:
            # update document
            resources.document(doc.id).update(update_data)
            # update count
            updated_count += 1
        else:
            print(f"Skipped Document {doc.id}")

    # show updated count
    print(f"Migration complete. Updated {updated_count} documents")


# main    
if __name__ == "__main__":
    modify_resource()