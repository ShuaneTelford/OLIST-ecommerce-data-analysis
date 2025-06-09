# OLIST e-commerce sales and logistics analysis

## Introduction

This project centres around the realistic business problem of warehouse creation and late delivery analysis that a developing e-commerce company like OLIST would face. This project was made to produce a data-driven solution and insights that would help in the decision-making and resource allocation for key stakeholders. Including executive management, the data analytics team, the warehousing operations team, and the logistics team.

## Project Overview

- Produced a unified relational database with existing OLIST data where members of a data analytics team could easily access, update, and query data
- Generated insightful queries related to potential stakeholder demands regarding the project’s problem statement
- Generated stored procedures that leverage the insight gained from queries to create an accessible way to query important metrics such as revenue, categorical popularity, and sales volume, through user-driven choices
- Created a Power BI dashboard which incorporates insights gained from SQL queries and showcases them in a visually appealing but informative report intended for all stakeholders to view, interact, and help form decisions

## Skills Gained From Project

- Refined database management skills such as database creation, importing existing, and ensuring separate tables follow relational database conventions (primary key, foreign key, fact vs. dimension table relations), and data checks for missing data in fact vs. dimension tables
- Refine skills using SQL, in particular, generate complex queries that showcase joins, datatype conversions, window functions, temporary tables, and nested CTEs
- Generated complex stored procedures to showcase strong command and understanding of SQL queries and program creation and leveraging T-SQL unique commands
- Produced a legible and interactive dashboard which yields complex and simple oversights that are both stylistically clear and informative through data

## Data Description (Find the dataset [here](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data))

The OLIST dataset captures a snapshot of e-commerce activities from late 2016 to the end of 2017. It includes information regarding customers, sellers, locations, orders, payment, product categories, delivery logistics, and product reviews. The length of time allows the data set to be suitable for trend and seasonality analysis. 

Database Diagram:

<img src="https://github.com/ShuaneTelford/OLIST-ecommerce-analysis/blob/main/Repo%20Images/Database%20Diagram.png" alt="" width="720"/>

## Tools Used
- SQL Server Management Studio (SSMS)
- T-SQL
- Power BI

<details>
  <summary><h2>Methodology</h2></summary>
  
  1. **Data Acquisition and Initial Exploration**
     - Acquire dataset from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data). The dataset contains various CSV files related to OLIST's e-commerce activities from late 2016 to the end of 2017.
     - Each CSV file was examined to understand its contents and structure.
  
  3. **Database Setup**
     - Data was imported into SSMS.
     - On import, primary keys and appropriate data types were prescribed to the necessary columns for each table to ensure data integrity and later calculations.
     - Foreign keys were assigned to established relationships between tables.
     - Records without the appropriate/missing primary --> foreign relation were removed, accounting for approximately 1.5% of the data
     
  5. **Data Analysis and Query Generation**
     - Order Volume Analysis
       - Analysed order volumes on a daily, weekly, and monthly basis.
       - Breakdown of order volumes by state and city.
     - Customer-Seller Matching Analysis
       - Evaluated customer-seller matches by location, from city to state levels.
       -  Generated summary cards to show the total shares of matches.
     - Revenue Analysis
       - Conducted monthly revenue analysis at both city and state levels.
       - Calculated gross revenue, cost of goods sold (COGS), net value, and monthly revenue share at the city and state levels.
     - Late Delivery Analysis
       - Analysed monthly late delivery distributions at the state level.
       - Produced summary cards highlighting monthly late deliveries.
     - Product Category Analysis
       - Identified monthly the most profitable products by state and city and the most profitable products overall.
       - Created a query which ranked product categories by volume.
     - Payment Type Analysis
       - Investigated the share of different payment types for each state.
  
  7. **Stored Procedure Generation**

| Stored Procedure Name   | User Inputs                                                                                                                                                       | Description                                                                                                                                                                                                         |
|-------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| GetLateDeliveries       | - startDate<br>- endDate<br>- period ('daily' or 'monthly')<br>- state (optional)<br>- city (optional)<br>- rankStart (optional)<br>- rankEnd (optional)<br>- option (0 or 1, use with rank range)                | Provides the volume of late deliveries based on the user's specified start and end dates, chosen time delimitation, and geographical or rank preferences.                                                         |
| GetOrderVolumes         | - startDate<br>- endDate<br>- period ('daily' or 'monthly')<br>- state (optional)<br>- city (optional)<br>- option_state (0 or 1)                                                                                            | Provides the volume of orders based on the user's specified start and end dates, chosen time delimitation, and geographical preferences.                                                                           |
| GetPopularCategories    | - startDate<br>- endDate<br>- period ('daily' or 'monthly')<br>- state (optional)<br>- city (optional)<br>- rankStart (optional)<br>- rankEnd (optional)                                                                  | Generates the order volume of product categories based on the user's specified start and end dates, chosen time delimitation, and geographical or rank preferences.                                               |
| GetOrderVolumesByRank   | - startDate<br>- endDate<br>- period ('daily' or 'monthly')<br>- state (optional)<br>- city (optional)<br>- rankStart (optional)<br>- rankEnd (optional)<br>- option (0 or 1, use with rank range)                      | Generates a ranked list of cities or states and order volumes based on the user's specified start and end dates, chosen time delimitation, and geographical or rank preferences.                                 |
| GetRevenueByLocation    | - startDate<br>- endDate<br>- period ('daily' or 'monthly')<br>- state (optional)<br>- city (optional)                                                                                                                      | Generates the NET Revenue based on the user's specified start and end dates, chosen time delimitation, and geographical preferences.                                                                             |


  5. **Power BI Dashboard Creation**
     - Import data from raw OLIST CSV files and clean and transform data to appropriate types like done in SSMS

  | Visual                                  | Description                                                                                                                                      |
|-----------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| Grand Total Sales and Revenue          | Create card visuals to display the grand total sales, grand total NET revenue, and profit rate.                                                |
| Top 5 and Bottom 5 Performing States   | Use bar charts to visualise the top 5 and bottom 5 performing states based on revenue and order volume.                                         |
| Product Categories                     | Use a scatter plot to show NET revenue and profit rate of different product categories, sized by total order volume. Accompany with a matrix detailing results of order volume, NET revenue, profit rate, and %Share of total net revenue per product category. |
| Payment Type Shares                   | Use a 100% stacked bar chart to display the share of each payment type by state.                                                                |
| Net Revenue Trend Line                | Create a line chart to display the trend of NET revenue over time with data labels.                                                              |
| Revenue and Profit Rate               | Create a matrix to show net revenue value and share, including profit rates for different product categories and states. Include a scatter plot to illustrate this matrix.                       |
| Order Volume Map                      | Use a filled map with a gradient to illustrate order volume concentration.                                                                      |
| 3D Scatter Plot of Product Size, Weight, and Days Late | Create a 3D scatter plot to visualise the relationship between product size, weight, and the number of days late.                                 |
| Monthly Order Volume Matrix           | Use a matrix to display the order volume for each month across the dataset’s date range with accompanying yearly totals and gradients showcasing the yearly share of total order volume.          |
| Seasonal Matrix of Late Order Share   | Create a matrix to show the share of late orders by season for each state with a colour gradient to help visualise the share %.                 |
| Box and Whisker Plot of Days Late by State | Create a box and whisker plot to show the distribution of days late for orders, broken down by state.                                           |

  - **Dashboard Assembly**
    - Arrange the created visuals into a cohesive and interactive dashboard.
    - Ensure visuals are linked appropriately to enable cross-filtering and dynamic interaction.

  - **Interactivity and Usability**
    - Utilise state and date slicers as well as zoom slicers. Link slicers to appropriate visuals to allow users to customise their view of a visual
    - Creation of custom tooltips that, when hovering over NET Revenue or the filled map display the total order volume for the specific date, limitations of product volume and revenue, and city-based order volume

</details>

## Final Dashboard
![](https://github.com/ShuaneTelford/OLIST-ecommerce-analysis/blob/main/Repo%20Images/Dashboard.gif)

Page 1:

<img src="https://github.com/ShuaneTelford/OLIST-ecommerce-analysis/blob/main/Repo%20Images/Dashboard%20page%201.jpg" />

Page 2:
<img src="https://github.com/ShuaneTelford/OLIST-ecommerce-analysis/blob/main/Repo%20Images/Dashboard%20page%202.jpg" />

## Conclusion

- This project resulted in a wide range of comprehensive and insightful SQL queries and stored procedures tailored to the requirements of various stakeholders. In addition, a Power BI dashboard combining effective visuals and data to provide a comprehensive and interactable experience which aids stakeholders in the decision-making process.
- This project showcases the refinement of various data analytics skills. From database management and importing of existing data, query generation from simple to advanced and comprehensive stored procedures. Finally, a visually clear and insightful data report showcasing the results gained and insights from data analysis to present to stakeholders.
- The project itself and the creation of the problem statement allowed me to operate in a fictitious but realistic work/project-oriented environment from stakeholder identification, stakeholder management, design document creation, database management, data analysis, and report creation.
