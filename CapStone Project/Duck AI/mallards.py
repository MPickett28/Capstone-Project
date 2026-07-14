"""
Download clearly labeled male and female Mallard photos from a Macaulay Library
Excel export.

Expected spreadsheet columns:
- ML Catalog Number
- Format
- Common Name
- Age/Sex

Install:
    pip install pandas openpyxl requests pillow

Run:
    python download_mallards.py

Optional:
    python download_mallards.py --limit-per-sex 500
    python download_mallards.py --excel "ML Library(1).xlsx"
"""

from __future__ import annotations

import argparse
import csv
import time
from io import BytesIO
from pathlib import Path

import pandas as pd
import requests
from PIL import Image, UnidentifiedImageError


REQUIRED_COLUMNS = {
    "ML Catalog Number",
    "Format",
    "Common Name",
    "Age/Sex",
}

# Only accept labels representing one clearly identified bird.
# Mixed-sex records, unknown sex, juveniles without sex, and counts above 1
# are intentionally excluded.
MALE_LABELS = {
    "Adult Male",
    "Adult Male – 1",
    "Adult Male - 1",
    "Male",
    "Male – 1",
    "Male - 1",
}

FEMALE_LABELS = {
    "Adult Female",
    "Adult Female – 1",
    "Adult Female - 1",
    "Female",
    "Female – 1",
    "Female - 1",
}


def clean_catalog_number(value: object) -> str | None:
    """Convert an Excel catalog number into a clean integer string."""
    if pd.isna(value):
        return None

    text = str(value).strip()

    # Excel may represent an integer as 123456789.0.
    if text.endswith(".0"):
        text = text[:-2]

    return text if text.isdigit() else None


def classify_sex(age_sex: object) -> str | None:
    """Return Male, Female, or None for ambiguous/unwanted records."""
    if pd.isna(age_sex):
        return None

    label = " ".join(str(age_sex).strip().split())

    if label in MALE_LABELS:
        return "Male"

    if label in FEMALE_LABELS:
        return "Female"

    return None


def build_image_urls(asset_id: str) -> list[str]:
    """
    Return Macaulay CDN URLs in preferred order.

    The script first requests a 1200-pixel image and then tries a larger
    fallback if the first URL is unavailable.
    """
    base = "https://cdn.download.ams.birds.cornell.edu/api/v1/asset"
    return [
        f"{base}/{asset_id}/1200",
        f"{base}/{asset_id}/1800",
    ]


def download_and_validate_image(
    session: requests.Session,
    asset_id: str,
    destination: Path,
    timeout: int = 45,
) -> tuple[int, int]:
    """Download an image, validate it with Pillow, and save it as JPEG."""
    last_error: Exception | None = None

    for url in build_image_urls(asset_id):
        try:
            response = session.get(url, timeout=timeout)
            response.raise_for_status()

            content_type = response.headers.get("Content-Type", "").lower()
            if "image" not in content_type:
                raise ValueError(
                    f"Expected image content but received {content_type or 'unknown'}"
                )

            with Image.open(BytesIO(response.content)) as image:
                image.load()
                width, height = image.size

                if width < 300 or height < 300:
                    raise ValueError(f"Image is too small: {width}x{height}")

                # Convert formats such as PNG or RGBA safely to standard JPEG.
                image = image.convert("RGB")
                image.save(destination, "JPEG", quality=95)

            return width, height

        except (
            requests.RequestException,
            UnidentifiedImageError,
            OSError,
            ValueError,
        ) as error:
            last_error = error

    raise RuntimeError(f"All image URLs failed: {last_error}")


def append_csv_row(csv_path: Path, fieldnames: list[str], row: dict[str, object]) -> None:
    """Append one row and create the header when the CSV is new."""
    is_new = not csv_path.exists()

    with csv_path.open("a", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)

        if is_new:
            writer.writeheader()

        writer.writerow(row)


def prepare_records(excel_path: Path) -> pd.DataFrame:
    """Read and filter the spreadsheet to clean Mallard photo records."""
    dataframe = pd.read_excel(excel_path)

    missing = REQUIRED_COLUMNS.difference(dataframe.columns)
    if missing:
        raise ValueError(
            "Spreadsheet is missing required columns: "
            + ", ".join(sorted(missing))
        )

    records = dataframe.loc[
        dataframe["Common Name"].astype(str).str.strip().eq("Mallard")
        & dataframe["Format"].astype(str).str.strip().str.casefold().eq("photo")
    ].copy()

    records["SexLabel"] = records["Age/Sex"].apply(classify_sex)
    records["AssetID"] = records["ML Catalog Number"].apply(clean_catalog_number)

    records = records.dropna(subset=["SexLabel", "AssetID"])
    records = records.drop_duplicates(subset=["AssetID"])

    return records


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Download male and female Mallard photos."
    )
    parser.add_argument(
        "--excel",
        default="ML Library.xlsx",
        help='Path to the Macaulay Excel export. Default: "ML Library.xlsx"',
    )
    parser.add_argument(
        "--output",
        default="Mallard_Dataset",
        help='Output folder. Default: "Mallard_Dataset"',
    )
    parser.add_argument(
        "--limit-per-sex",
        type=int,
        default=None,
        help="Maximum images per sex. Default: all qualifying records.",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=0.35,
        help="Seconds between download attempts. Default: 0.35",
    )
    args = parser.parse_args()

    excel_path = Path(args.excel)
    output_path = Path(args.output)
    male_path = output_path / "Male"
    female_path = output_path / "Female"

    if not excel_path.exists():
        raise FileNotFoundError(
            f'Could not find "{excel_path}". Put the script beside the '
            "spreadsheet or supply --excel with the correct path."
        )

    male_path.mkdir(parents=True, exist_ok=True)
    female_path.mkdir(parents=True, exist_ok=True)

    records = prepare_records(excel_path)

    male_records = records.loc[records["SexLabel"].eq("Male")].copy()
    female_records = records.loc[records["SexLabel"].eq("Female")].copy()

    # Randomize records so a limited dataset is not dominated by spreadsheet order.
    male_records = male_records.sample(frac=1, random_state=42)
    female_records = female_records.sample(frac=1, random_state=42)

    if args.limit_per_sex is not None:
        male_records = male_records.head(args.limit_per_sex)
        female_records = female_records.head(args.limit_per_sex)

    selected = pd.concat([male_records, female_records], ignore_index=True)
    selected = selected.sample(frac=1, random_state=42).reset_index(drop=True)

    print(f"Qualifying male records:   {len(male_records)}")
    print(f"Qualifying female records: {len(female_records)}")
    print(f"Total selected:            {len(selected)}")

    manifest_path = output_path / "downloaded_images.csv"
    failures_path = output_path / "failed_downloads.csv"

    manifest_fields = [
        "filename",
        "sex",
        "asset_id",
        "age_sex_original",
        "width",
        "height",
    ]
    failure_fields = [
        "asset_id",
        "sex",
        "age_sex_original",
        "error",
    ]

    downloaded = {"Male": 0, "Female": 0}
    skipped_existing = 0
    failed = 0

    session = requests.Session()
    session.headers.update(
        {
            "User-Agent": (
                "Educational Mallard dataset downloader "
                "(contact the script owner for details)"
            )
        }
    )

    for index, row in selected.iterrows():
        sex = str(row["SexLabel"])
        asset_id = str(row["AssetID"])
        folder = male_path if sex == "Male" else female_path
        filename = f"ML{asset_id}.jpg"
        destination = folder / filename

        print(
            f"[{index + 1}/{len(selected)}] {sex}: ML{asset_id}",
            end=" ... ",
            flush=True,
        )

        if destination.exists():
            print("already exists")
            skipped_existing += 1
            continue

        try:
            width, height = download_and_validate_image(
                session=session,
                asset_id=asset_id,
                destination=destination,
            )

            append_csv_row(
                manifest_path,
                manifest_fields,
                {
                    "filename": str(destination.relative_to(output_path)),
                    "sex": sex,
                    "asset_id": asset_id,
                    "age_sex_original": row["Age/Sex"],
                    "width": width,
                    "height": height,
                },
            )

            downloaded[sex] += 1
            print(f"saved ({width}x{height})")

        except Exception as error:
            failed += 1
            print(f"FAILED: {error}")

            # Remove a partially written file, if one exists.
            destination.unlink(missing_ok=True)

            append_csv_row(
                failures_path,
                failure_fields,
                {
                    "asset_id": asset_id,
                    "sex": sex,
                    "age_sex_original": row["Age/Sex"],
                    "error": str(error),
                },
            )

        time.sleep(max(args.delay, 0))

    print("\nFinished")
    print(f"New male images:      {downloaded['Male']}")
    print(f"New female images:    {downloaded['Female']}")
    print(f"Existing images:      {skipped_existing}")
    print(f"Failed downloads:     {failed}")
    print(f"Dataset folder:       {output_path.resolve()}")


if __name__ == "__main__":
    main()
