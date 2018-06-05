# Secondary Malignancy Risk Calculator

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2018, University of Wisconsin Board of Regents

## Description

This MATLAB tool uses the DICOM dataset (CT, RTSS, Dose, Plan) to compute the risk of secondary malignancy using various risk models and parameters. MATLAB is a registered trademark of MathWorks Inc. 

## Installation

To install the Secondary Malignancy Risk Calculator as a MATLAB App, download and execute the `Secondary Malignancy Risk Calculator.mlappinstall` file from this directory. If downloading the repository via git, make sure to download all submodules by running  `git clone --recursive https://github.com/mwgeurts/secondary_risk`.

## Usage and Documentation

To run this application, run the App or call `SecondaryRiskCalculator` from MATLAB. Once the application interface loads, click browse and select the folder containing DICOM plan data (CT, RTSS, Dose, and Plan are all required). Once all data is loaded, the application will automatically process and display the results.

See the [wiki](../../wiki/) for information on configuration parameters, available models, and additional documentation.

## License

Released under the GNU GPL v3.0 License.  See the [LICENSE](LICENSE) file for further details.