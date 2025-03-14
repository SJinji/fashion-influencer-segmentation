# Analysis and Enhancement of Fashion Influencer Segmentation

This repository contains my submission for the Heuritech Data Scientist technical test. The project focuses on **social media account segmentation** using fashion-related data. The goal is to analyze and improve the current segmentation methodology, providing actionable insights into user behavior and fashion trends.

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Repository Structure](#repository-structure)
3. [Setup Instructions](#setup-instructions)
4. [Notebooks](#notebooks)
5. [Data](#data)
6. [Results](#results)
7. [Contact](#contact)

---

## Project Overview

### Problem Statement
The current segmentation methodology for social media accounts is based solely on the number of followers:
- **Mainstream**: ≤ 12,000 followers
- **Trendy**: 12,000–40,000 followers
- **Edgy**: > 40,000 followers

This approach lacks granularity and fails to capture nuanced categories like **luxury enthusiasts**, **sportswear lovers**, or **streetwear influencers**. The goal of this project is to:
1. Analyze the current segmentation methodology.
2. Propose and implement an improved segmentation approach.
3. Provide actionable insights into user behavior and engagement.

### Key Features
- **Data Analysis**: Exploratory analysis of follower counts, engagement metrics, and content patterns.
- **Segmentation**: Improved segmentation using weighted fashion categories and KMeans clustering.
- **Visualization**: Clear and interpretable visualizations of segment characteristics.
- **Reproducibility**: Modular code and detailed documentation for easy replication.

---

## Repository Structure
<img width="675" alt="image" src="https://github.com/user-attachments/assets/45c0a3ff-66a0-4eda-8515-6db59388d42a" />

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/SJinji/fashion-influencer-segmentation.git
cd fashion-influencer-segmentation
```

### 2. Install Dependencies

Ensure you have Python 3.8+ installed. Then, install the required packages:

```bash
pip install -r requirements.txt
```

### 3. Run the Notebooks

This repository contains two Jupyter notebooks:

*   **Q1_current_segmentation_analysis.ipynb**: Analyzes the current segmentation methodology.
    ```bash
    jupyter notebook notebooks/Q1_current_segmentation_analysis.ipynb
    ```
*   **Q2_enhanced_segmentation.ipynb**: Implements an improved segmentation model.
    ```bash
    jupyter notebook notebooks/Q2_enhanced_segmentation.ipynb
    ```

## Notebooks

### 1. Q1_current_segmentation_analysis.ipynb

**Objective:** Analyze the current segmentation methodology.

**Key Features:**

*   Follower distribution by segment.
*   Engagement metrics (likes, comments, engagement rate).
*   Content distribution by segment.
*   SQL Queries (src/sql/Q1_current_segmentation.sql): Provides SQL queries used for data exploration and analysis related to the current segmentation methodology.

### 2. Q2_enhanced_segmentation.ipynb

**Objective:** Propose and implement an improved segmentation approach.

**Key Features:**

*   Weighted fashion categories (luxury, sportswear, footwear, etc.).
*   KMeans clustering for segment creation.
*   Segment characteristics and engagement analysis.
*   SQL Queries (src/sql/Q2_enhanced_segmentation.sql): Contains SQL queries for rule-based method for the enhanced fashion account segmentation.

## Data

### Raw Data

The raw data files are located in the `data/raw` directory:

*   **MART_AUTHORS.csv**: Metadata about authors (e.g., bio, follower counts).
*   **MART_AUTHORS_SEGMENTATIONS.csv**: Current segmentation data.
*   **MART_IMAGES_LABELS.csv**: Image labels predicted by deep learning models.
*   **MART_IMAGES_OF_POSTS.csv**: Links between images and posts.

### Processed Data

*   **fashion_segments_final.csv**: Final segmentation results from the enhanced model (located in `data/processed`).

## Results

### Key Findings

**Current Segmentation:**

*   Accounts near segment boundaries (e.g., 12,000 or 40,000 followers) show similar engagement patterns.
*   The current methodology fails to capture fashion-specific behaviors.

**Enhanced Segmentation:**

*   Identified luxury fashion, sportswear enthusiasts, and streetwear influencers as distinct segments.
*   High-engagement accounts are concentrated in the luxury and sportswear segments.

### Visualizations

Visualizations generated by the notebooks are saved in the `reports/visuals` directory and include:

*   Follower distribution by segment.
*   Engagement rate distribution by segment.
*   Top fashion categories for each segment.

## Final Report
technical_test_report.pdf (reports/technical_test_report.pdf): This PDF document contains the final report summarizing the analysis and findings. It provides detailed answers to three key questions related to the segmentation analysis and proposed improvements.

## Contact

For questions or feedback, feel free to reach out:

**Name:** Jinji Shen

**Email:** jinji.shen@essec.edu

**LinkedIn:** https://www.linkedin.com/in/jinji-shen-363aa0125/
