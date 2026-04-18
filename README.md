<div align="center">
  <a href="https://github.com/aeb56">
    <img src="./assets/header.svg" alt="Abel-Emanuel Bancu — AI engineer · researcher · CTO" width="100%" />
  </a>
</div>

<div align="center">
  <a href="https://www.linkedin.com/in/abelbancu/"><img src="https://img.shields.io/badge/LinkedIn-abelbancu-0a0a0a?style=for-the-badge&logo=linkedin&logoColor=7cf5c5&labelColor=050507" alt="LinkedIn" /></a>
  <a href="https://optivise.ai"><img src="https://img.shields.io/badge/CTO-Optivise-0a0a0a?style=for-the-badge&logo=rocket&logoColor=7cf5c5&labelColor=050507" alt="Optivise" /></a>
  <img src="https://img.shields.io/badge/MSc_AI-Distinction-0a0a0a?style=for-the-badge&logo=graduation-cap&logoColor=7cf5c5&labelColor=050507" alt="MSc AI Distinction" />
  <img src="https://img.shields.io/badge/PhD-incoming_@_Kent-0a0a0a?style=for-the-badge&logo=flask&logoColor=7cf5c5&labelColor=050507" alt="PhD incoming" />
</div>

<br />

<div align="center">
  <a href="https://git.io/typing-svg">
    <img src="https://readme-typing-svg.demolab.com?font=JetBrains+Mono&weight=500&size=20&duration=3200&pause=1100&color=7CF5C5&center=true&vCenter=true&width=760&lines=training+agents+that+don%27t+just+reach+the+goal;they+move+like+you%27d+want+a+robot+to;behaviour-first+robot+navigation;low-hallucination+AI+%40+Optivise;reward+function%3A+%7B+survive+thesis%2C+build+startup+%7D+%E2%9C%93" alt="Typing banner" />
  </a>
</div>

---

## whoami

```txt
> AI engineer / researcher. CTO at Optivise. MSc AI — Distinction, City (London).
> Incoming PhD at Kent on behaviour-first robot navigation: policies that don't
> just reach the goal, they move like you'd want a robot to.
>
> I like agents. I like the ones that learn, and I like the ones that ship.
```

My reward function this past year had two massive goals: **survive my thesis** and **build a startup**. The model converged. Conclusion? I apparently enjoy the chaos.

---

## currently

- 🛰 **CTO @ [Optivise](https://optivise.ai)** — trustworthy, low-hallucination AI for teams who can't afford to be wrong.
- 🧪 **Research** — behaviour-first deep RL for robot navigation. PPO on Stable-Baselines3, Hyperion GPU cluster. Reward shaping that cares about *how* a policy moves, not just whether it reaches the goal.
- 🎓 **PhD-bound at Kent** — picking up where the MSc left off: the agent solved the problem we specified, not the one we cared about. That gap is the thesis.
- 🧩 **Paper** — contributor on [**PALMS**](https://arxiv.org/abs/2602.07519), a Rescorla-Wagner-style associative learning model.

---

## featured work

<table>
  <tr>
    <td width="50%" valign="top">
      <h3>🚁 Drone Navigation via Deep RL</h3>
      <p><em>INM363 MSc Thesis — Distinction</em></p>
      <p>PPO agent learning 3D collision-free navigation in procedurally generated environments. Reward shaping explored the gap between <em>reaching</em> the goal and <em>moving like you'd want a drone to</em>. Ran on Hyperion GPU cluster.</p>
      <sub>C# · Unity ML-Agents · PPO · Stable-Baselines3</sub>
      <br /><br />
      <a href="https://github.com/aeb56/DRONENAVIGATIONRL"><img src="https://img.shields.io/badge/source-DRONENAVIGATIONRL-7cf5c5?style=flat-square&labelColor=050507" /></a>
    </td>
    <td width="50%" valign="top">
      <h3>🧠 PALMS</h3>
      <p><em>Associative learning model · published team</em></p>
      <p>Python implementation of a Rescorla-Wagner-style learning model. My contribution: simulation logic + experimental pipeline. Paper lives on arXiv.</p>
      <sub>Python · NumPy · SciPy · Matplotlib</sub>
      <br /><br />
      <a href="https://github.com/aeb56/PALMS"><img src="https://img.shields.io/badge/source-PALMS-7cf5c5?style=flat-square&labelColor=050507" /></a>
      <a href="https://arxiv.org/abs/2602.07519"><img src="https://img.shields.io/badge/paper-arXiv-b8ffde?style=flat-square&labelColor=050507" /></a>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>🏥 Clinical Prediction Models</h3>
      <p><em>Brain tumour classification · heart-attack risk</em></p>
      <p>Two applied-ML projects: MRI-based tumour classification with transfer learning, and tabular risk scoring on clinical features. Focus on calibration and honest-about-uncertainty outputs.</p>
      <sub>PyTorch · scikit-learn · Grad-CAM</sub>
    </td>
    <td width="50%" valign="top">
      <h3>🗣 Word-Prediction Language Model</h3>
      <p><em>Small-scale next-token model, from scratch</em></p>
      <p>Byte-pair tokenisation, transformer block, trained on a curated corpus. Built to understand the stack end-to-end, not to beat SOTA.</p>
      <sub>PyTorch · Transformers · BPE</sub>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>🌊 Underwater Depth Estimation</h3>
      <p><em>Monocular depth in hostile lighting</em></p>
      <p>CV project on depth estimation where the usual priors (sky, linear perspective) break. Encoder-decoder with attention, custom loss for turbidity.</p>
      <sub>PyTorch · Depth · Attention</sub>
    </td>
    <td width="50%" valign="top">
      <h3>🚛 Dispatch Optimisation</h3>
      <p><em>Fleet routing under real-world constraints</em></p>
      <p>OR + learning hybrid: constraint solver for hard rules, bandit for soft preferences learned from operator overrides.</p>
      <sub>Python · OR-Tools · Bandits</sub>
    </td>
  </tr>
</table>

> Most of my current work is in private repos at Optivise. The public side here is thesis + coursework + paper code — enough to show the taste, not the whole kitchen.

---

## stack

<div align="center">

**agents & research**

<img src="https://img.shields.io/badge/PyTorch-EE4C2C?style=for-the-badge&logo=pytorch&logoColor=white" />
<img src="https://img.shields.io/badge/Stable_Baselines3-7cf5c5?style=for-the-badge&labelColor=050507&color=050507" />
<img src="https://img.shields.io/badge/Unity_ML--Agents-000?style=for-the-badge&logo=unity&logoColor=white" />
<img src="https://img.shields.io/badge/NumPy-013243?style=for-the-badge&logo=numpy" />
<img src="https://img.shields.io/badge/scikit--learn-F7931E?style=for-the-badge&logo=scikit-learn&logoColor=white" />
<img src="https://img.shields.io/badge/Hugging_Face-FFD21E?style=for-the-badge&logo=huggingface&logoColor=000" />

**production & llm apps**

<img src="https://img.shields.io/badge/Anthropic_Claude-d97757?style=for-the-badge&logo=anthropic&logoColor=white" />
<img src="https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white" />
<img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white" />
<img src="https://img.shields.io/badge/React-61DAFB?style=for-the-badge&logo=react&logoColor=000" />
<img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" />
<img src="https://img.shields.io/badge/Postgres-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" />
<img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" />

**infra & research ops**

<img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=000" />
<img src="https://img.shields.io/badge/CUDA-76B900?style=for-the-badge&logo=nvidia&logoColor=white" />
<img src="https://img.shields.io/badge/Weights_&_Biases-FFBE00?style=for-the-badge&logo=weightsandbiases&logoColor=000" />
<img src="https://img.shields.io/badge/Slurm-000?style=for-the-badge&logo=linux&logoColor=7cf5c5" />
<img src="https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white" />

</div>

---

## the numbers

<div align="center">

<a href="https://github.com/aeb56">
  <img height="165" src="https://github-readme-stats.vercel.app/api?username=aeb56&show_icons=true&count_private=true&include_all_commits=true&hide_border=true&bg_color=050507&title_color=7cf5c5&icon_color=7cf5c5&text_color=d4d4d8&ring_color=7cf5c5" />
</a>
<a href="https://github.com/aeb56">
  <img height="165" src="https://github-readme-stats.vercel.app/api/top-langs/?username=aeb56&layout=compact&hide_border=true&bg_color=050507&title_color=7cf5c5&text_color=d4d4d8&langs_count=8&exclude_repo=parameter-golf" />
</a>

<br />

<a href="https://github.com/aeb56">
  <img src="https://github-readme-streak-stats.herokuapp.com/?user=aeb56&hide_border=true&background=050507&stroke=7cf5c5&ring=7cf5c5&fire=b8ffde&currStreakLabel=7cf5c5&sideNums=d4d4d8&currStreakNum=7cf5c5&dates=d4d4d8&sideLabels=7cf5c5" />
</a>

</div>

---

## contribution graph

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/aeb56/aeb56/output/github-snake-dark.svg" />
    <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/aeb56/aeb56/output/github-snake.svg" />
    <img alt="Snake eating my contribution graph" src="https://raw.githubusercontent.com/aeb56/aeb56/output/github-snake.svg" />
  </picture>
</div>

---

## what I care about

- **Behaviour over benchmarks.** A policy that reaches the goal with a reward graph that looks great but moves like a drunk pigeon is not a solved problem.
- **Honest AI.** At Optivise I spend most of my time thinking about when a model should say *I don't know* instead of hallucinating. Cheaper to build trust once than to apologise forever.
- **Research that ships.** The point of a paper is that someone can use it. Same for a thesis, same for a product.

---

## where to find me

<div align="center">

<a href="https://www.linkedin.com/in/abelbancu/"><img src="https://img.shields.io/badge/LinkedIn-connect-7cf5c5?style=for-the-badge&logo=linkedin&logoColor=050507&labelColor=050507" /></a>
<a href="https://optivise.ai"><img src="https://img.shields.io/badge/Optivise-what_we're_building-7cf5c5?style=for-the-badge&logo=rocket&logoColor=050507&labelColor=050507" /></a>
<a href="https://arxiv.org/abs/2602.07519"><img src="https://img.shields.io/badge/arXiv-PALMS-7cf5c5?style=for-the-badge&logo=arxiv&logoColor=050507&labelColor=050507" /></a>

</div>

<br />

<div align="center">
  <sub>built with far too much dark-mode, one espresso too many, and a soft spot for agents that actually move like they mean it.</sub>
</div>

<!--
  hidden note to future-me / recruiters grepping the source:
  if you're reading this, press `/` on my portfolio site for a terminal.
  try `cat thesis` or `sudo`. you'll see.
-->
