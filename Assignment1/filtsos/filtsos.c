/* Date  : <2018-04-09>
 * Author: Niko Jozic
 * Course: ITSB-M DSP2
 * Code based on following references:
 * [1]"Tutorial: Decoding Audio (Windows)", msdn.microsoft.com, 2018. [Online]. Available: https://msdn.microsoft.com/en-us/library/windows/desktop/dd757929(v=vs.85).aspx. [Accessed: 23-03-2018].
 * [2]Copied from wav.c provided in lecture
 */

#include <stdio.h>
#include <stdint.h>
#include "fdacoefs.h"

int main(int argc, char* argv[])
{

	if(argc < 3)
	{
		printf("CLI call: wav input.wav output.wav\r\n");
		return 0;
	}

	FILE* inputFile = fopen(argv[1],"rb");
	FILE* outputFile = fopen(argv[2], "wb");
	WaveHeader waveHeader;

	// Skip wave header till we know how much bytes are written
	fseek(outputFile, sizeof(WaveHeader), 0);
	fread(&waveHeader, sizeof(WaveHeader), 1, inputFile);

	int16_t buffer[2048], leftSample[1024], rightSample[1024],leftFiltered[1024], rightFiltered[1024];

	for (uint32_t blockCount = 0; blockCount < waveHeader.dataHeader.DataLength; blockCount += sizeof(int16_t)*2048)
	{
		fread(&buffer, sizeof(int16_t), 2048, inputFile);

		// Deinterleave
		for (uint16_t i = 0; i < 1024; i++)
		{
			leftSample[i]  = buffer[2 * i];
			rightSample[i] = buffer[2 * i + 1];
		}

		// Function einbinden
        njfilter(leftSample,&leftFiltered[0]);
        njfilter(rightSample,&rightFiltered[0]);

		// Interleave
		for (uint16_t i = 0; i < 1024; i++)
		{
			buffer[2 * i]     = leftFiltered[i];
			buffer[2 * i + 1] = rightFiltered[i];
		}

		fwrite(&buffer, sizeof(int16_t), 2048, outputFile);
	}

	// Go to beginning of output file and write updated wave header
	fseek(outputFile, 0, 0);

	// Write updated wave header
	fwrite(&waveHeader, sizeof(WaveHeader), 1, outputFile);

	fclose(outputFile);
	fclose(inputFile);

	return 0;
}

//filterfunction
void njfilter(int16_t x[], int16_t y[]){
	double z[MWSPT_NSEC][2] = {0};
	double xk[MWSPT_NSEC] = {0};
	double yk[MWSPT_NSEC] = {0};

	double tmp;

	for(int k = 0; k < BLOCKSIZE; k++){
		tmp = x[k];

		for(int i=0; i<MWSPT_NSEC; i++){
			xk[i] = 0;
			yk[i] = 0;

			// calculate the xk and yk Values
			for( int k = 2 ; k > 0 ; k-- )
            {
                xk[i] -= ( z[i][k-1] * a[i][k] );
                yk[i] += ( z[i][k-1] * b[i][k] );
            }

			//shift the first z-value to the second z-value
			z[i][1] = z[i][0];

			//add the Left-Side of the Segment
			tmp += xk[i];

			//Shift the result of the left-Side of the segment to the first z-value
			z[i][0] = tmp;

			//add the Right-Side of the Segment
			tmp = (tmp*b[i][0]) + yk[i];
		}
		y[k] = (int16_t)tmp;
	}
}
