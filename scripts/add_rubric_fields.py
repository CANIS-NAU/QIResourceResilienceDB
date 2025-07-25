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

# Fields to add (if not present) to each document's rubric
fields_to_add = {
    "accessibilityFeatures": [],
    "additionalComments": None,
    "ageBalance": None,
    "appropriate": True,
    "avoidsAgeism": True,
    "avoidsAppropriation": True,
    "avoidsCondescension": True,
    "avoidsRacism": True,
    "avoidsSexism": True,
    "avoidsStereotyping": True,
    "avoidsVulgarity": True,
    "contentAccuracy": 0,
    "contentCurrentness": 0,
    "contentTrustworthiness": 0,
    "culturalGroundednessHopi": 0,
    "culturalGroundednessIndigenous": 0,
    "genderBalance": [],
    "lifeExperiences": [],
    "queerSexualitySpecific": False,
    "totalScore": 0
}

def add_fields_to_resource():
    """Adds missing fields to the 'rubric' field of each resource document."""
    db = firestore.client()
    resources = db.collection("resources")
    updated_count = 0

    print(f"Dry run mode: {'ON' if dry_run else 'OFF'}")

    for doc in resources.stream():
        data = doc.to_dict()
        updates = {}

        if "rubric" in data and data["rubric"]: # Check if 'rubric' field exists and is not empty
            rubric = data["rubric"]
            for field in fields_to_add:
                if field not in rubric:
                    # set fields with existing values if they exist
                    if field == "contentCurrentness":
                        updates[f"rubric.{field}"] = rubric.get("contentCurrent", 0)
                    elif field == "contentAccuracy":
                        updates[f"rubric.{field}"] = rubric.get("contentAccurate", 0)
                    elif field == "contentTrustworthiness":
                        updates[f"rubric.{field}"] = rubric.get("contentTrustworthy", 0)
                    else:
                        updates[f"rubric.{field}"] = fields_to_add[field]

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
    add_fields_to_resource()
