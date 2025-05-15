AI Use Case: Intelligent Submission Intake for Underwriting Support 

Use Case Name: 

AI-Powered Submission Intake and Risk Summary Generation 

Shape 

Business Problem: 

Underwriters receive complex and unstructured submission packs from brokers, including MRCs, SOVs, loss run reports, and emails. Manually extracting, validating, and entering relevant data is time-consuming, error-prone, and delays risk assessment and quoting. 

Shape 

AI Solution Summary: 

Implement an AI-powered intake engine that leverages document intelligence (OCR + NLP) and agentic workflows to: 

Parse and understand unstructured documents (MRC, SOV, loss run, broker email). 

Extract key risk and policy data into a structured format. 

Generate a risk summary for underwriters. 

Trigger downstream systems (e.g., PAS, Exposure, Sanctions, Pricing) using APIs. 

Present a submission dashboard with all required data and insights for underwriter decision-making. 

Shape 

Key Capabilities Involved: 

Document AI (NLP) 

Semantic understanding (LLM) 

RAG (Retrieval-Augmented Generation) for context-aware summaries 

Agentic AI for orchestrating API calls 

Workflow Automation 

Integration with core systems (PAS, Pricing, Exposure) 

Shape 

User Stories 

Shape 

EPIC 1: Ingest Submission Pack and Extract Key Data 

User Story 1.1: 
As an AI system, I want to ingest MRC, SOV, and loss run documents (PDF/Word/Excel) submitted by the broker so that I can begin processing the submission. 

User Story 1.2: 
As an AI system, I want to apply document classification and NLP techniques to identify document types (MRC, SOV, Loss Run, Email) to process them appropriately. 

User Story 1.3: 
As an AI system, I want to extract and standardize key data points (e.g., UMRC, Sum Insured, Reinsurance Type, Jurisdiction) from MRC documents using AI-based entity extraction. 

User Story 1.4: 
As an AI system, I want to parse tabular data from the SOV to extract location-level risk values, construction type, protection details (e.g., sprinklers), etc. 

User Story 1.5: 
As an AI system, I want to extract historical claim information from loss run reports, including year, claim type, paid amounts, and loss ratios. 

User Story 1.6: 
As an AI system, I want to parse broker email commentary to identify client intent, cover requirements, and risk narrative to support underwriting context. 

Shape 

EPIC 2: Summarize and Validate Extracted Risk Data 

User Story 2.1: 
As an AI system, I want to generate a concise summary of the submission highlighting key risk attributes, loss history, and broker proposition, so that the underwriter has a ready overview. 

User Story 2.2: 
As an underwriter, I want to review and edit the AI-generated summary and extracted data to correct any anomalies before proceeding with risk assessment. 

User Story 2.3: 
As an AI system, I want to flag any inconsistencies, missing values, or confidence thresholds below an acceptable limit for manual review. 

Shape 

EPIC 3: Populate Core Systems and Trigger UW Workflow 

User Story 3.1: 
As an AI agent, I want to enter the validated data into the Policy Admin System via API to generate a unique Underwriting Reference Number. 

User Story 3.2: 
As an AI agent, I want to use the UW Reference Number to initiate the underwriting workflow and link the submission to the appropriate underwriter’s workbench. 

Shape 

EPIC 4: Trigger API Calls for Risk Checks 

User Story 4.1: 
As an AI agent, I want to call the Exposure Management + Cat modelling APIs using risk location and sum insured data to retrieve exposure aggregation insights. 

User Story 4.2: 
As an AI agent, I want to invoke the Sanctions Screening API using insured party details to confirm compliance. 

User Story 4.3: 
As an AI agent, I want to call the Pricing Engine API with all extracted data to generate a base price and rating factors. 

Shape 

EPIC 5: Present to Underwriter for Decision 

User Story 5.1: 
As an underwriter, I want to view a dashboard summarizing the extracted data, risk profile, exposure/sanction/pricing results, and broker proposition in one place so I can make an informed decision. 

User Story 5.2: 
As an underwriter, I want the ability to provide feedback on the AI-extracted summary and data so the system can improve accuracy over time. 

Shape 

Optional Enhancements (Future Scope) 

Feedback Loop for AI Learning: Capture underwriter corrections to refine AI models. 

Integration with Market Repositories: Validate UMRCs and contract references with PPL or LIMOSS. 

Predictive Risk Scoring: Train models to assign a preliminary risk score based on historical loss and profile similarity. 

Voice to Text: Allow audio broker notes to be converted and analyzed. 

Shape 

Output/Deliverables 

Structured Data Extract: JSON/XML/Tabular format of all required fields. 

Risk Summary: Plain-text narrative of submission in underwriter-friendly language. 

Submission Dashboard: All submission info, documents, results from systems. 

Audit Trail: End-to-end log of extraction, decisions, and user feedback. 

 
