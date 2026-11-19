# masai_careloop_clinics
CareLoop Clinics — No-Show Guard
CareLoop Clinics — No-Show Guard

This repository walks through an end-to-end analysis for CareLoop Clinics, which operates eight outpatient clinics across six Indian cities. The goal is straightforward: clean up the raw booking records, figure out where and when missed appointments happen, flag risky visits the evening before, and turn post-visit call notes into structured reasons the front desk can act on.

What the Data Shows and Where to Start

Out of 990 cleaned appointments, 22.0% ended in a no-show. Looking at the numbers across clinics, lead times, and reminders, three practical priorities stand out:

* Focus on long-lead bookings first. Appointments booked 1 to 7 days in advance have a 16.2% no-show rate, and 8 to 14 days sit at 17.4%. Once a booking is made 15 to 30 days ahead, that rate jumps to 30.0%, and for 31+ days it reaches 60.5%.
* Make sure reminders actually go out. Visits where no reminder was sent had a 30.8% no-show rate, compared to 15.3% for visits that received a reminder.
* Prioritize the busiest high-miss clinics. Among clinics with at least 95 bookings, Hadapsar Care Centre in Pune had the highest no-show rate at 27.3% (39 missed out of 143), with Malviya Nagar Clinic in Jaipur close behind at 26.8% (38 out of 142).

What Each File Does

* 01_ingest_clean.ipynb — Reads the raw CSVs, quarantines malformed rows into data/rejected_rows.json, removes duplicates, handles missing values and IQR outliers, pulls clinic temperatures from Open-Meteo, and exports appointments_clean.csv, clinics_enriched.csv, and load_data.sql.
* 02_queries.sql — Contains the SQL queries for clinic-level no-show rates, lead-time bands, month-over-month changes, and city rankings against the overall average.
* 03_model.ipynb — Splits the cleaned bookings 80/20 (test_size=0.2, random_state=42), compares Logistic Regression, Decision Trees, and Random Forests using 5-fold cross-validation, checks cutoffs on out-of-fold probabilities, and writes test_risk_scores.csv.
* 04_genai.ipynb — Sends a sample of 10 follow-up call notes to the Gemini API using JSON mode and Pydantic validation, then cross-tabs the extracted root causes against whether a reminder was sent.

Model Choice and Threshold

In 03_model.ipynb, candidate models are compared on 5-fold cross-validated ROC-AUC using only the training set so the test set stays untouched until the end. (Add your exact CV ROC-AUC and final test metrics here after running the notebook in Colab.)

For flagging risky appointments, the notebook compares a 0.50 cutoff against 0.35 on out-of-fold training probabilities and uses 0.35. In practice, missing a likely no-show leaves a doctor slot empty, while a false alarm just means an extra confirmation phone call, so catching more true no-shows (higher recall) is worth the trade-off.

Running the Project

1. Put appointment.csv, clinics.csv, and followup_notes.csv into a data/ folder.
2. Run 01_ingest_clean.ipynb to produce the cleaned CSVs and load_data.sql.
3. Load load_data.sql and run 02_queries.sql in MySQL 8 (if you use SQLiteOnline instead, skip any CREATE DATABASE or USE lines).
4. Run 03_model.ipynb to generate test_risk_scores.csv.
5. Run 04_genai.ipynb and enter your Gemini API key when input() prompts for it. Remember to clear cell outputs before downloading or pushing to GitHub so your key is never saved in the notebook.

A Few Caveats

* Correlation vs. causation: These patterns come from historical booking logs, not a controlled experiment, so reminder and lead-time figures show associations rather than proven causal effects.
* Random train/test split: Splitting randomly (random_state=42) rather than chronologically means the same patient can show up in both the training and test sets.
* Small text sample: Because of free-tier API rate limits, 04_genai.ipynb only processes the first 10 call notes, which gives a helpful directional check rather than a full-clinic breakdown.
