import click
import gspread
from oauth2client.service_account import ServiceAccountCredentials
import pandas as pd
import logging
from logdecorator import log_on_start, log_on_end, log_on_error, log_exception

@click.command()
@click.option('--gsheet_csv', required=True, type=click.Path(exists=True), help='Google Spreadsheet converted to csv')
@click.option('--cellranger_metadata_tsv', required=True, type=click.Path(exists=True), help='Cellranger and Irods metadata tsv table')
@click.option('--file_paths_10x_tsv', required=True, type=click.Path(exists=True), help='tsv table of cellranger file paths')

@log_on_start(logging.INFO, (
    "\ngsheet_csv: {gsheet_csv:s}\n"
    + "cellranger_metadata_tsv: {cellranger_metadata_tsv:s}\n"
    + "file_paths_10x_tsv: {file_paths_10x_tsv:s}"))
def gsheet_to_csv(creds_json, gsheet, output_csv_name):
    """Use google API and Service Account to convert google Spreadsheet to local csv file."""
    creds = ServiceAccountCredentials.from_json_keyfile_name(creds_json)
    client = gspread.authorize(creds)
    sheet = client.open(gsheet).sheet1
    data = sheet.get_all_values()
    headers = data.pop(0)
    df = pd.DataFrame(data, columns=headers)
    df = df.stack().str.replace(',',';').unstack()
    df.to_csv(output_csv_name, index=False)
    logging.info(df.head())

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO) # set logging level
    gsheet_to_csv()
