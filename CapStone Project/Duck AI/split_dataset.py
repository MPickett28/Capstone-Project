"""
Split the downloaded Mallard dataset into Training, Validation, and Testing sets.

Input:
Mallard_Dataset/
    Male/
    Female/

Output:
Mallard_Data/
    Training/
        Male/
        Female/
    Validation/
        Male/
        Female/
    Testing/
        Male/
        Female/

Usage:
    python split_dataset.py
"""

from pathlib import Path
import random
import shutil

SOURCE = Path("Mallard_Dataset")
DEST = Path("Mallard_Data")

TRAIN_RATIO = 0.70
VALID_RATIO = 0.15
TEST_RATIO = 0.15

RANDOM_SEED = 42
COPY_FILES = True   # False = move files instead of copying


def split_class(class_name: str):
    src = SOURCE / class_name

    if not src.exists():
        print(f"Missing folder: {src}")
        return

    images = []
    for ext in ("*.jpg", "*.jpeg", "*.png"):
        images.extend(src.glob(ext))

    random.shuffle(images)

    total = len(images)
    train_count = int(total * TRAIN_RATIO)
    valid_count = int(total * VALID_RATIO)

    train = images[:train_count]
    valid = images[train_count:train_count + valid_count]
    test = images[train_count + valid_count:]

    print(f"\n{class_name}")
    print(f"Total: {total}")
    print(f"Training: {len(train)}")
    print(f"Validation: {len(valid)}")
    print(f"Testing: {len(test)}")

    for subset, files in {
        "Training": train,
        "Validation": valid,
        "Testing": test,
    }.items():

        folder = DEST / subset / class_name
        folder.mkdir(parents=True, exist_ok=True)

        for file in files:
            destination = folder / file.name

            if COPY_FILES:
                shutil.copy2(file, destination)
            else:
                shutil.move(file, destination)


def main():
    random.seed(RANDOM_SEED)

    if not SOURCE.exists():
        raise FileNotFoundError(
            f"Could not find '{SOURCE}'. Put this script beside the Mallard_Dataset folder."
        )

    split_class("Male")
    split_class("Female")

    print("\nFinished!")
    print(f"Dataset ready in: {DEST.resolve()}")


if __name__ == "__main__":
    main()
