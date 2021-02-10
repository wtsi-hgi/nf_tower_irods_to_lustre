import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import math
import sys
import os
from matplotlib import rcParams
rcParams.update({'figure.autolayout': True})

def visualise_dataset(Data,plot_value,min_limit,max_limit):
    plt.style.use('ggplot')
    plt.rcParams['axes.edgecolor'] = '#333F4B'
    plt.rcParams['axes.linewidth'] = 0.8
    plt.rcParams['xtick.color'] = '#333F4B'
    plt.rcParams['ytick.color'] = '#333F4B'
    fig, (ax) = plt.subplots(1,1)
    fig.set_size_inches(8.5, 11)
    N = Data.__len__()
    for i in range(0,(max_number_of_entries-N)):
        Data=Data.append(pd.Series(), ignore_index=True)
        Data.loc[Data.sample_sanger_id.isna(), 'sample_sanger_id'] = i*" "
    ind = np.arange(Data.__len__())  # the x locations for the groups
    plt.barh(ind, Data[plot_value],align='center', height=0.9)
    ax.set_yticks(ind)
    ax.set_xlim(min_limit, max_limit)
    ax.set_yticklabels(Data["sample_sanger_id"])
    ax.invert_yaxis()  # labels read top-to-bottom
    ax.set_xlabel(plot_value)
    # ax.set_title(plot_value)
    fig.autofmt_xdate()
    plt.show()
    return fig

def visualise_file(name,plot_value,max_number_of_entries,output_folder):
    # Use a breakpoint in the code line below to debug your script.
    Data = pd.read_csv(name,sep="\t")  # Press ⌘F8 to toggle the breakpoint.
    for value in plot_value.split(","):
        Reads = Data[value]

        try:
            Reads = Reads.str.replace("%", "").astype(float)
        except:
            next
        max_limit=Reads.max()
        min_limit = Reads.min()-0.1*Reads.min()
        import matplotlib.backends.backend_pdf
        filename = value.replace(" ", "_")
        pdf = matplotlib.backends.backend_pdf.PdfPages(f"{output_folder}/{filename}.pdf")
        for i in range(-1,math.ceil(Reads.__len__()/max_number_of_entries)-1):
            d1 = (i+1)*max_number_of_entries
            d2 = (i+2)*max_number_of_entries
            Data[value] = Reads
            Data_trunctioned=Data.iloc[d1:d2]
            fig = visualise_dataset(Data_trunctioned,value,min_limit,max_limit)
            pdf.savefig(fig) #
        pdf.close()

if __name__ == '__main__':
    
    file = sys.argv[1] #"Submission_Data_Pilot_UKB.file_metadata.tsv"
    print(f"File loaded is: {file}")
    plot_value = "Number of Reads,Valid Barcodes,Sequencing Saturation"
    max_number_of_entries=10 #here you specify how many samples to use per pdf page.
    output_folder = os.getcwd() #sys.argv[2]#"output_files"
    visualise_file(file,plot_value,max_number_of_entries,output_folder)
    print(f"Output has been saved in output_folder: {file}")
