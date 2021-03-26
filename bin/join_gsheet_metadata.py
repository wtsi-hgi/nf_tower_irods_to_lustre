import os
import click
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
def join_gsheet_metadata(gsheet_csv,cellranger_metadata_tsv,file_paths_10x_tsv):
    """join tables."""
    gsheet_csv='Submission_Data_Pilot_UKB.csv'
    cellranger_metadata_tsv='Submission_Data_Pilot_UKB.file_metadata.tsv'
    file_paths_10x_tsv='Submission_Data_Pilot_UKB.file_paths_10x.tsv'
    
    logging.info(os.getcwd())
    logging.info(os.listdir())
    
    df_gsheet = pd.read_csv(gsheet_csv)
    df_cellranger_metadata = pd.read_csv(cellranger_metadata_tsv, delimiter='\t')
    df_file_paths_10x = pd.read_csv(file_paths_10x_tsv, delimiter='\t')
    
    nrows_f = df_file_paths_10x[df_file_paths_10x.columns[0]].count()
    nrows_m = df_cellranger_metadata[df_cellranger_metadata.columns[0]].count()
    nrows_g = df_gsheet[df_gsheet.columns[0]].count()
    logging.info('n rows file_paths_10x: ' + str(nrows_f))
    logging.info('n rows cellranger_metadata ' + str(nrows_m))
    logging.info('n rows gsheet_csv: ' + str(nrows_g))
    
    df_gsheet['experiment_id'] = df_gsheet['SANGER SAMPLE ID']
    df_gsheet['n_pooled'] = df_gsheet['N_DONOR']
    
    logging.info('n unique experiment_id in file_paths_10x: ' + str(len(df_file_paths_10x.experiment_id.unique())))
    logging.info('n unique experiment_id in cellranger_metadata: ' + str(len(df_cellranger_metadata.experiment_id.unique())))
    logging.info('n unique experiment_id in gsheet_csv: ' + str(len(df_gsheet.experiment_id.unique())))
    
    logging.info('merge all 3 dataframes on experiment id columns:')
    df_tmp = df_file_paths_10x.merge(df_cellranger_metadata, on = 'experiment_id', how = 'outer')
    df_outer_merge = df_tmp.merge(df_gsheet, on = 'experiment_id', how = 'outer')
    logging.info('merge done.')
    logging.info('n rows df_outer_merge: ' + str(df_outer_merge[df_outer_merge.columns[0]].count()))
    logging.info('n unique experiment_id in df_outer_merge: ' + str(len(df_outer_merge.experiment_id.unique())))
    
    logging.info('write output df')
    df_outer_merge.to_csv('nf_fetch_all_samples_metadata.tsv', sep='\t', encoding='utf-8', index=False)
    
    logging.info('write samples to deconv only.')
    df_for_deconv = df_outer_merge[(df_outer_merge.n_pooled.notnull()) & (df_outer_merge.n_pooled != 0)]
    logging.info('n rows df_for_deconv: ' + str(df_for_deconv[df_for_deconv.columns[0]].count()))
    df_for_deconv.to_csv('nf_fetch_samples_to_deconv.tsv', sep='\t', encoding='utf-8', index=False)
    
    logging.info('write samples not convoluted only.')
    df_no_deconv = df_outer_merge[(df_outer_merge.n_pooled.isnull()) | (df_outer_merge.n_pooled == 0)]
    logging.info('n rows df_no_deconv: ' + str(df_no_deconv[df_no_deconv.columns[0]].count()))
    df_no_deconv.to_csv('nf_fetch_samples_no_deconv.tsv', sep='\t', encoding='utf-8', index=False)
    logging.info('script done.')
    
if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO) # set logging level
    join_gsheet_metadata()
