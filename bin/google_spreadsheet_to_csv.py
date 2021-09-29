import click
import gspread
from oauth2client.service_account import ServiceAccountCredentials
import pandas as pd
import logging
from logdecorator import log_on_start, log_on_end, log_on_error, log_exception

@click.command()
@click.option('--creds_json', required=True, type=click.Path(exists=True), help='Google API credentials')
@click.option('--gsheet', required=True, help='name of input Google spreadsheet')
@click.option('--output_csv_name', required=True, help='path or name of output csv file')

@log_on_start(logging.INFO, (
    "\ncreds_json: {creds_json:s}\n"
    + "gsheet: {gsheet:s}\n"
    + "output_csv_name: {output_csv_name:s}"))
def gsheet_to_csv(creds_json, gsheet, output_csv_name):
    """Use google API and Service Account to convert google Spreadsheet to local csv file."""
    creds = ServiceAccountCredentials.from_json_keyfile_name(creds_json)
    client = gspread.authorize(creds)
    sheet = client.open(gsheet).worksheet("Connect_Valid")
    data = sheet.get_all_values()
    headers = data.pop(0)
    df = pd.DataFrame(data, columns=headers)
    df = df.stack().str.replace(',',';').unstack()
    df.to_csv(output_csv_name, index=False)
    logging.info(df.head())

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO) # set logging level
    gsheet_to_csv()
