# A Buyer-Seller approach using an MBTI agent-based model

This repository has the code used to create agent-based models developed with personality types inspired by MBTI (Myers-Briggs Type Indicator).

For more details on the theory behind the implementations and the Buyer-Seller approach, please see some of the published papers:

- [Using MBTI Agents to Simulate Human Behavior in a Work Context](https://link.springer.com/chapter/10.1007/978-3-030-92843-8_25) - *Springer*
- [Using the Myers-Briggs Type Indicator (MBTI) for Modeling Multiagent Systems](https://www.seer.ufrgs.br/rita/article/view/RITA_Vol29_Nr1_42) - *Revista de Informática Teórica e Aplicada*
- [Extending BEN architecture for modeling MBTI agents](https://ut3-toulouseinp.hal.science/hal-03500245/) - *HAL Open Science*
- [Simulating Work Teams using MBTI agents](https://link.springer.com/book/10.1007/978-3-031-22947-3) - *MABS 2022 – The 23rd International Workshop on Multi-Agent-Based Simulation*
- Um estudo do Myers-Briggs Type Indicator (MBTI) para modelagem de sistemas multiagentes no apoio a processos de recrutamento e seleção nas empresas (Best Papers) - *14th WESAAC - UTFPR*

## Prerequisites

- [GAMA Platform - V1.8.2](https://gama-platform.org/)

## How to use?

- Clone this repo and open the [mbti-buyer-seller folder](./models/mbti-buyer-seller/).
- You can check the [buyer-seller](./models/mbti-buyer-seller/buyer-seller.gaml) model to explore how to use the MBTI inspired model, or you can simply import the [mbti.gaml](./models/mbti-buyer-seller/mbti.gaml) file into your own model.


## How to run using Headless Mode?

- Run the following command in your headless folder: `gama-headless.bat "<PATH-OF-YOUR-LOCALWORKSPACE>\headless_input\gamaDefaultMBTI.xml" /output`

The [gamaDefaultMBTI.xml](./headless_input/gamaDefaultMBTI.xml) file has an example of how to run 10 simulations (nine with the same SEED and another one with a different seed) using headless mode passing some parameters (seed value is inherited from the XML file). You can find `gama-headless.bat` in the Gama Program's File folder (usually **C:\Program Files\Gama\headless** if you use Windows).
