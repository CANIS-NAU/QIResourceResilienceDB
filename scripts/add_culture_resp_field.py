import firebase_admin
from firebase_admin import credentials, firestore

#set credentials
cred = credentials.Certificate("./.secret/sunrise-dev.json")
#initialize firebase
firebase_admin.initialize_app(cred)

CULTURAL_RESPONSE_MAPPING = {
    0 : "none",
    1 : "low",
    2 : "some",
    3 : "good",
    4 : "high",
    5 : "high",
    -1 : ""
}

#function definition


def add_field_to_resource():
    """adds field (if not present) \"culturalResponsiveness\" to resource documents, initialized using the old \"culturalResponsivness\" value"""

    # init variables
    db = firestore.client()

    resources = db.collection("resources")

    updated_count = 0

    # iterate through documents
    for doc in resources.stream():

        # convert to py dictionary
        data = doc.to_dict()

        # check if contains key "cultural_responsiveness"
        if "culturalResponsiveness" in data:
            # print already has field
            print(f"Skipped document {doc.id}: 'culturalResponsiveness' already present.")
    
        # add field to document
        else:
            # get old integer value
            old_value = data.get( "culturalResponsivness", -1 )

            # access dictionary with value to get appropriate normalized string
            update_data = { "culturalResponsiveness" : CULTURAL_RESPONSE_MAPPING.get( old_value, "" )}

            # update resource in database
            resources.document(doc.id).update(update_data)

            # increment update counter
            updated_count += 1

            # print update
            print(f"Successfully added field to document {doc.id}")
            
    # show updated count
    print(f"Migration complete. Updated {updated_count} documents")


# main    
if __name__ == "__main__":
    add_field_to_resource()