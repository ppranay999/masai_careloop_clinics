# CareLoop Clinics: Appointment No-Show Guard

An end-to-end data engineering, SQL analytics, predictive modeling, and LLM audit pipeline built to reduce missed outpatient appointments across CareLoop Clinics' 8 regional branches.

---

## Project Architecture

| Module | File | Responsibility |
| :--- | :--- | :--- |
| **1. Data Pipeline** | `01_data_pipeline.ipynb` | Row-level schema quarantine (`rejected_rows.json`), median imputation, $1.5 \times \text{IQR}$ winsorization, Open-Meteo weather enrichment, and deterministic SQL seed generation. |
| **2. SQL Analytics** | `02_clinic_analytics.sql` | Branch-level no-show leaderboards, booking lead-time cohort decay, month-over-month trend tracking (`LAG`), and intra-city clinic ranking (`RANK`). |
| **3. Risk Scoring** | `03_noshow_risk_modeling.ipynb` | Leak-free `ColumnTransformer` pipelines comparing Logistic Regression, Pruned Decision Trees, and Tuned Random Forests via 5-fold CV, plus recall-oriented threshold calibration. |
| **4. NLP Call Audit** | `04_followup_nlp_audit.ipynb` | Structured root-cause extraction from unstructured front-desk follow-up call notes using Gemini Flash and Pydantic v2 validation. |

---

## Key Analytical Findings

1. **Data Hygiene:** Out of 1,020 raw appointment records, 30 malformed/incomplete rows were quarantined or filtered, yielding **990 clean records** across 16 standardized features.
2. **Branch Bottlenecks:** Among high-volume branches ($\ge 95$ bookings), **Hadapsar Care Centre (Pune)** recorded the highest no-show rate at **27.3%**.
3. **Lead-Time Decay:** Bookings scheduled **1–7 days** in advance had a **16.2%** no-show rate, whereas bookings made **>14 days** out escalated sharply to **30.0%–60.5%**.
4. **Reminder Impact & Model Selection:**
   * **Logistic Regression** outperformed tree ensembles in 5-fold cross-validation (`ROC-AUC ≈ 0.77`, holdout `ROC-AUC ≈ 0.79`).
   * Holding other factors constant, sending a pre-visit reminder reduces no-show odds by **~69%**.
   * Lowering the classification cutoff from `0.50` to **`0.35`** boosts holdout recall to **~57%**, prioritizing slot recovery over low-cost front-desk verification calls.
5. **Call-Note Audit:** 100% of audited no-shows classified under `forgot_or_no_reminder` corresponded to bookings where `reminder_sent = No` in the operational database.

---

## Operational Recommendations

* **Night-Before Risk Triage:** Score next-day appointments every evening using the Logistic Regression pipeline at a `0.35` probability cutoff and route flagged patients to the morning confirmation queue.
* **Two-Stage Reminders for Long Lead Times:** Trigger an automated SMS/WhatsApp confirmation 7 days prior—and a second reminder 24 hours prior—for any appointment booked more than 14 days in advance.
* **Branch-Specific Outreach:** Prioritize front-desk phone verification at high-attrition branches such as Hadapsar Care Centre.

---

## Caveats & Scope Limitations

* **Associational Inference:** Historical reminder effectiveness reflects observational correlations rather than a randomized controlled trial.
* **Partitioning Strategy:** The 80/20 train/test split is stratified randomly rather than temporally; future iterations should use time-based holdouts and patient-grouped splits (`GroupKFold`).
* **LLM Audit Sample:** The NLP pipeline currently evaluates a 10-note diagnostic sample and requires batch queuing before full production rollout.
