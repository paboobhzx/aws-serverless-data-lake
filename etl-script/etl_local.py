import pandas as pd 
import os 

def run_etl():
    print ("Starting ETL Process...")
    # 1 - Read the CSV file
    input_file = '../sales_data.csv'
    if not os.path.exists(input_file):
        print(f"Error: file {os.path.abspath(input_file)}  not found")
        return
    print(f"Reading data from {input_file}")
    df = pd.read_csv(input_file)

    #2 - Clean and Enrich the data
    #A - Fix Dates (Text -> Real Date)
    df['date'] = pd.to_datetime(df['date'])
    #B - Creating a "Total Value" column (quantity * price)
    df['total_value'] = df['quantity'] * df['price']
    #C - Filter: Looking only for high value orders (>50)
    high_value_df = df[df['total_value'] > 50]
    print("Preview Transformation...")
    print(high_value_df.head())
    #3 Load (Save as Parquet)
    output_file = 'processed_data.parquet'
    high_value_df.to_parquet(output_file, index=False)
    print(f"Data saved to: {output_file}")
    print("ETL Job finished succesfully!")
run_etl()