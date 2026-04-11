# geefetch: Google Earth Engine Fast Easy Terrestrial Covariate Harvester

**Date:** 2026-04-11
**Author:** Max Moldovan and Adam Sparks
**Status:** PROPOSAL — awaiting review and direction

remotes::install_github("max578/geefetch", subdir = "geefetch")


Hi Adam. Let's do a rapid R&D project to design, build and deploy R geefetch (Google Earth Engine Fast Easy Terrestrial Covariate Harvester) which is a fusion of rgee and envfetch. I've learned I need about 3 hours to 2 days to develop a fully functional prototype - see my recent https://github.com/AAGI-AUS/PESTO and https://github.com/AAGI-AUS/kernR. Would you be able to (fluently) review/upgrade the implementation plan, give me a reasonably rapid feedback on the developments in progress when I ask for it (so, can be a few days - rapid enough), and I need your expert review at completion.

See the attached .md's for more formal introduction, open for comments, not necessary immediate (it is quite a process, regardless of the initial plan).


Importantly, we are making the point - we don't need large teams of "busy" professionals anymore in projects like nert, it will be the lead developer + a panel of experts, deploying R&D products within days, not months and years. This is a projected massive saving for GRDC and gaining truly strategic advantage globally through rapid R&D&E (so, kind of, there must be already such initiatives in US etc.). I stop here - less talks more business + tangible results from me.


The plan for your revie


just making sure coding is what is expected (should be relatively east for you?). I can start any time, but I will be 




geefetch: Google Earth Engine Fast Easy Terrestrial Covariate Harvester

Creative & Strategic Name Brainstorm for an R Package Integrating envfetch + rgee
The integration creates a powerful, one-stop tool for pulling, caching, and summarising spatio-temporal environmental data from Google Earth Engine directly in R. The name should feel modern, evoke satellite/earth-observation imagery, data “harvesting”, and environmental workflows, while remaining short, memorable, and CRAN-friendly.



Here is a developed idea for R geefetch package, intended to follow an elegant R nert architecture centres on a single dispatcher (read_tern()) with short aliases and dataset-specific handlers, complemented by convenience wrappers (e.g. read_smips(), read_slga()) and a batch extraction function (collect_tern_data()) that returns a data.table of point values across multiple locations and dates. Presen a feasible implementation plan leading to the world to R package. Output two documents: executive_summary.md with the executive summary and implementationplan.md 




geefetch: Google Earth Engine Fast Easy Terrestrial Covariate Harvester

Honest, Critical & Optimistic Assessment of the Integration
Plusses (Optimistic View)

Huge user value: envfetch’s excellent spatio-temporal summarisation + caching on top of rgee creates a genuinely powerful workflow — users can go from an sf object + time column to clean environmental covariates in one or two lines.

Performance win: envfetch’s built-in caching and smart summarisation solves one of the biggest pain points of raw rgee usage (repeated expensive calls).

Strategic positioning: This package would become the go-to tool for anyone doing environmental modelling, ecology, precision agriculture, or climate impact studies in R. It fills a real gap.

Future-proof: GEE is one of the richest free data sources on the planet — integrating it deeply gives the package long-term relevance.


Minuses (Critical View)

Heavy dependency burden: rgee brings reticulate + Python + Google Earth Engine authentication. This is the single biggest friction point — many users hate dealing with Python environments.

Installation & onboarding complexity: Users must set up a Google account, enable Earth Engine, authenticate via rgee::ee_Initialize(), and manage Python dependencies. This is significantly harder than a pure-R package.

CRAN compliance risk: Heavy reticulate-based packages are often rejected or moved to Suggests only. Full integration could make CRAN submission difficult or impossible without major compromises.

Maintenance overhead: You become responsible for compatibility whenever rgee or envfetch updates. Google can also change GEE APIs or quotas.

Scope & identity: The resulting package would no longer be a “light” tool — it becomes a relatively heavy environmental data client.

Balanced Verdict

Worth doing if your target audience is serious environmental / ecological researchers who already use GEE and are comfortable with a bit of setup friction.

Not worth doing (or do it as a lightweight wrapper only) if you want a clean, easy-to-install CRAN package for a broad audience.

Recommended realistic path:

Make rgee a strong Suggests dependency and provide a high-level wrapper like geefetch::extract() that internally uses envfetch + rgee. Keep the core package lightweight and optional for GEE users.









Please critically and sceptically revise **both documents** (the full package documentation and the overall package structure / design) once again.

Push the quality aggressively so that the final package becomes **the clear top-tier R package** in the Google Earth Engine / spatio-temporal environmental data extraction space — surpassing current alternatives in usability, consistency, and professionalism.

### Specific Goals

- **Mimic the structure and quality of `nert`**  
  Adopt the same high standards of documentation, function organisation, roxygen2 style, output consistency, vignette quality, and user experience that make `nert` an excellent package. Use `nert` as the direct structural and stylistic template.

- **Tailor everything specifically for Google Earth Engine (via `rgee`)**  
  Design the package architecture, function names, workflows, and documentation explicitly around GEE + `rgee`, while deeply integrating the strengths of `envfetch`.

- **Make it exceptionally versatile and extremely easy to use**  
  - Support both simple one-line workflows for beginners **and** advanced, highly customisable workflows for power users.  
  - Prioritise an intuitive, forgiving, and well-documented API.  
  - Ensure the package feels welcoming and “for everyone” while still being powerful enough for complex research needs.

### Task Requirements
- Perform a ruthless, sceptical review of every function, roxygen2 header, vignette, README section, and exported object.  
- Eliminate any ambiguity, inconsistency, or unnecessary complexity.  
- Raise documentation quality to the highest possible standard (clear, concise, professional, and educational).  
- Ensure the package structure is logical, consistent, and scalable.

Please produce fully revised versions of both documents, clearly highlighting all changes made and justifying any major decisions.

Focus on making this the **definitive, best-in-class** R package for working with Google Earth Engine data.



Please critically and sceptically review the **entire geefetch package** — including its overall architecture, DSL layer, backends, inference engine, experimental features, and others documents and discussed.

Provide an uncompromising, rigorous assessment that includes:

- Honest identification of strengths, weaknesses, risks, and potential failure points
- Expert recommendations for **better implementations** where the current design can be improved


**Revised Prompt:**

Please work through the development phases **one at a time**. 

For each phase:
- Execute the work carefully on the **local machine only** (do not push to GitHub or perform any remote operations unless I explicitly ask).
- After completing the phase, provide a **brief progress summary**.
- Clearly inform me of any issues, blockers, decisions made, or important observations.

Do not proceed to the next phase until I confirm or give further instructions.

Start with Phase 1 and follow this approach consistently throughout the project.







Please design and execute a **comprehensive, package-wide automated testing suite** for the entire **geefetch** package.

### Requirements

- Identify **every exported function** (and S3/S4 methods) in the package.
- For **each function**, systematically test **every available argument**:
  - Default values
  - All valid argument combinations
  - Edge cases (empty data, single-row data, very large inputs, extreme parameter values, etc.)
  - Invalid inputs (to verify proper error handling)
- Ensure every function behaves **exactly as intended and documented**.
- Use **local multicore capabilities** (`parallel`, `future`, `doParallel`, or `pbapply` with multiple cores) to accelerate testing wherever possible.

### Output Requirements

Produce a clear, professional test report with the following sections:

1. **Testing Coverage Summary**  
   - Total number of exported functions tested  
   - Total number of argument combinations evaluated  
   - Test execution time and hardware used

2. **Issues Identified**  
   For every issue found, provide:
   - Function name and specific argument(s) involved
   - Clear description of the problem
   - Minimal reproducible example
   - How the issue was addressed (code change, documentation update, etc.)
   - Status (fixed / partially fixed / deferred with reason)

3. **Remaining Limitations / Open Issues**  
   Any known constraints that could not be fully resolved.

4. **Recommendations**  
   Suggested improvements for robustness, performance, or documentation.

Please be thorough, critical, and exhaustive. If any function or argument combination fails or behaves unexpectedly, treat it as a high-priority item and show exactly how you resolved it.





You are an expert R package developer and software engineering mentor with 15+ years of experience building high-quality, maintainable scientific R packages.

I have just completed a major project: developing **gretaR** — a next-generation Bayesian modeling package that re-implements and significantly improves upon the original greta package using a pure torch backend.

Now, looking back critically, I want your honest and constructive feedback on this question:

**What could I have done better to make the entire project significantly shorter in duration while simultaneously achieving higher quality?**

Please analyze the full scope of the project based on our conversation history, including:
- Overall architecture decisions
- Backend choice (torch vs alternatives)
- DSL design and compatibility with greta
- Feature scope (symbolic model imputation, mgcv-style splines, experimental features, etc.)
- Testing strategy
- Documentation approach
- Planning and incremental development process

For each major area, provide:
1. What was likely done sub-optimally (that caused unnecessary length or lower quality)
2. What you would have done differently to **save substantial time**
3. How that change would have **improved final quality**
4. A concrete recommendation or alternative approach

Structure your response as a clear, numbered list of key lessons learned / improvements, ordered from most impactful to least.

Be direct, specific, and ruthless — do not hold back on criticism if the project became bloated or inefficient. Focus on principles of lean software development, good scoping, minimal viable product thinking, and high-leverage decisions in R package development.

End with a short "Top 5 Things I Should Have Done Differently" summary.





---

**Prompt for Claude: replace to package name**



One more error is here, never seen before:

browseVignettes(package = "geefetch")
No vignettes found by browseVignettes(package = "geefetch")

Your task is to perform a **complete, rigorous, package-wide argument-level audit and testing** of the entire **geefetch** package to verify that every function works exactly as intended and produces correct results.

**Verification Criteria**
   - Function runs without crashing
   - Returns the documented object type and structure
   - Handles all documented argument values correctly
   - Gracefully errors on invalid input with helpful messages

### Required Output Format

Produce a professional, clearly structured test report with these sections, adding to @progress_phases.md:


1. **Detailed Test Results**  
   For each function (use clear headings):
   - Function name and signature
   - Number of test cases run
   - Summary: All passed / Issues found

2. **Issues Identified**  
   For every problem (no matter how small):
   - Function name + specific argument(s)
   - Minimal reproducible example
   - Exact error or unexpected behaviour
   - How the issue was addressed (code change, documentation update, or recommended fix)
   - Status: Fixed / Partially fixed / Deferred (with reason)

4. **Overall Assessment & Recommendations**  
   - Package robustness rating (Excellent / Good / Needs Work)
   - Any remaining limitations or untested edge cases
   - Suggestions for future automated testing (e.g., `testthat` suite, CI integration)

Be exhaustive, critical, and precise. Do not let the error, observed or not, to occur again. If anything does not behave exactly as expected, treat it as a high-priority item and show exactly how you resolved (or would resolve) it.


---

This prompt is optimised for Claude Code: it is structured, explicit, smart about combinations, forces clear reporting, and maximises the chance of catching subtle bugs while remaining practical.  

Would you like a slightly shorter version or any additional instructions added (e.g., specific focus on symbolic imputation or mgcv splines)? Just say the word and I’ll refine it instantly.

