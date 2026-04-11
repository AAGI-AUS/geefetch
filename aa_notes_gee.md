# geefetch: Google Earth Engine Fast Easy Terrestrial Covariate Harvester

**Date:** 2026-04-11
**Author:** Max Moldovan and Adam Sparks
**Status:** PROPOSAL — awaiting review and direction




Hi Adam. Let's do a rapid R&D project to design, build and deploy R geefetch (Google Earth Engine Fast Easy Terrestrial Covariate Harvester) which is a fusion of rgee and envfetch. I've learned I need from 3 hours to 2 days to develop a fully functional prototype - see my recent https://github.com/AAGI-AUS/PESTO and https://github.com/AAGI-AUS/kernR. Would you be able to review/upgrade the implementation schedule and give me a reasonably rapid feedback on the development, when I ask for it. (so, can be a few days, rapid enough). The plan for your revie


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




