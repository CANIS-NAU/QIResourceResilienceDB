import firebase_admin
from firebase_admin import credentials, firestore

#set credentials
cred = credentials.Certificate("./.secret/sunrise-dev.json")
#initialize firebase
firebase_admin.initialize_app(cred)


def delete_fields():
    """Removes the fields \"culturalResponsivness\" and \"culturalResponse\" from documents containing them"""

    #init db/vars
    db = firestore.client()

    updated_count = 0

    # get resource document
    resources = db.collection("resources")

    for doc in resources.stream():

        data = doc.to_dict()
        update_data = {};
    # ensure contains updated field before deleting
        if "culturalResponsiveness" in data:   
        # check contains culturalResponse
            if "culturalResponse" in data:
                # remove field
                    # set updated field
                update_data = {"culturalResponse" : firestore.DELETE_FIELD}
                    # pass update to db
                resources.document(doc.id).update(update_data)
                    # increment counter
                updated_count += 1
                    # print update
                print(f"successfully removed field 'culturalResponse' from document {doc.id}")
            else:
                print(f"Skipped document {doc.id}, does not contain 'culturalResponse'.")

            # check contains culturalResponsivness
            if "culturalResponsivness" in data:
                # remove field
                update_data = {"culturalResponsivness" : firestore.DELETE_FIELD}

                resources.document(doc.id).update(update_data)

                updated_count += 1

                print(f"successfully removed field 'culturalResponsivness' from document {doc.id}")

            else:
                print(f"Skipped document {doc.id}, does not contain 'culturalResponsivness'.")

        else:
            print(f"Skipped document {doc.id}, does not contain updated 'culturalResponsiveness' field")
            
    # print final count
    print(f"Migration complete. Updated {updated_count} documents")



if __name__ == "__main__":
    delete_fields()