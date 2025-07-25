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

# Set credentials
cred = credentials.Certificate("./.secret/sunrise-dev.json")
# Initialize Firebase
firebase_admin.initialize_app(cred)

# Fields to remove from the rubric field
fields_to_remove = [
    "avoidAgeism",
    "avoidAppropriation",
    "avoidCond",
    "avoidLanguage",
    "avoidRacism",
    "avoidSexism",
    "avoidStereotyping",
    "contentAccurate",
    "contentCurrent",
    "contentTrustworthy",
    "experienceBalance",
    "accurate",
    "authenticity",
    "consistency",
    "culturallyGrounded",
    "current",
    "language",
    "modularizable",
    "notMorallyOffensive",
    "productionValue",
    "relevance",
    "socialSupport",
    "trustworthySource",
]


def remove_fields_from_resource():
    """Removes old fields from the 'rubric' field of each resource document."""
    db = firestore.client()
    resources = db.collection("resources")
    updated_count = 0

    print(f"Dry run mode: {'ON' if dry_run else 'OFF'}")

    for doc in resources.stream():
        data = doc.to_dict()
        updates = {}

        if "rubric" in data and data["rubric"]: # Check if 'rubric' field exists and is not empty
            rubric = data["rubric"]
            for field in fields_to_remove:
                if field in rubric:
                    updates[f"rubric.{field}"] = firestore.DELETE_FIELD

            if updates:
                if not dry_run:
                    resources.document(doc.id).update(updates)
                print(f"Removed fields from document {doc.id}:")

                for key in updates.keys():
                    print(f"  {key}")
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
    remove_fields_from_resource()