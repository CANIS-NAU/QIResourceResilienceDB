import firebase_admin
import argparse
from firebase_admin import credentials, firestore

# Set up argument parser
parser = argparse.ArgumentParser(description="Add missing fields to rubric field in resources in Firestore.")
parser.add_argument(
    "--not-dry-run",
    action="store_false",
    help="If set, will update the database. If not set, will only print what would be done (dry run).",
    dest="dry_run",
    default=True)
args = parser.parse_args()
dry_run = args.dry_run

# Mapping of old rubric fields to new fields
def map_string_to_boolean(entry):
    if entry in [True, False]:
        return entry
    elif entry in ["Yes", "No"]:
        return entry == "Yes"
    return None

# Set credentials
cred = credentials.Certificate("./.secret/sunrise-dev.json")
# Initialize Firebase
firebase_admin.initialize_app(cred)

def modify_rubric_fields():
    """Updates currently existing rubric fields to match new typing"""
    db = firestore.client()
    resources = db.collection("resources")
    updated_count = 0

    print(f"Dry run mode: {'ON' if dry_run else 'OFF'}")

    for doc in resources.stream():
        data = doc.to_dict()
        updates = {}

        if "rubric" in data and data["rubric"]:  # Check if 'rubric' field exists and is not empty
            rubric = data["rubric"]

            if "appropriate" in rubric:
                updates["rubric.appropriate"] = map_string_to_boolean(rubric["appropriate"])

            if updates:
                if not dry_run:
                    resources.document(doc.id).update(updates)

                print(f"Updated document {doc.id} with fields:")

                for key, value in updates.items():
                    print(f"  {key}: {value}")
                print()

                updated_count += 1
            else:
                print(f"No update needed for document {doc.id}")
                print()
        else:
            print(f"Document {doc.id} has no 'rubric' field.")
            print()

    print(f"Total documents updated: {updated_count}")


# Main
if __name__ == "__main__":
    modify_rubric_fields()