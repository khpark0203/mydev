import PyPDF2
import sys
import os

filelist = ["rodin_big_data_processing_cover.pdf", "rodin_big_data_processing.pdf"]

num = len(filelist)
output = PyPDF2.PdfFileWriter()

for filename in filelist:
	input = PyPDF2.PdfFileReader(open(filename,"rb"))
	for j in range(input.getNumPages()):
		output.addPage(input.getPage(j))

outputStream = open("final.pdf","wb")
output.write(outputStream)
outputStream.close()