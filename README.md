# SQL Server Toolkit (Production-Oriented)

> Scripts I use when something breaks in production.

Collection of SQL Server scripts used in real-world environments for monitoring, troubleshooting, performance analysis, maintenance, and database documentation.

This repository is focused on practical SQL Server operations in production-oriented systems, especially environments where reliability, diagnostics, and maintainability matter.

Many of these scripts were created or adapted while working with financial and transactional systems.

---

# 📂 Repository Structure

Scripts are organized by operational purpose instead of object type.

## documentation/

Database documentation and metadata enrichment.

| Script                       | Description                                                             |
| ---------------------------- | ----------------------------------------------------------------------- |
| add_column_description.sql   | Adds `MS_Description` metadata to table columns                         |
| column_descriptions.sql      | Retrieves existing column descriptions                                  |
| data_dictionary.sql          | Generates a basic database dictionary                                   |
| enriched_data_dictionary.sql | Extended data dictionary including PK/FK relationships and descriptions |

---

## maintenance/

Operational and maintenance utilities.

| Script                            | Description                            |
| --------------------------------- | -------------------------------------- |
| disable_all_constraints.sql       | Disables all constraints               |
| disable_all_triggers.sql          | Disables all triggers                  |
| enable_all_constraints.sql        | Re-enables constraints with validation |
| rebuild_or_reorganize_indexes.sql | Generates index maintenance commands   |
| reseed_identity_all_tables.sql    | Reseeds identity values                |

---

## metadata/

Database structure and dependency analysis.

| Script                          | Description                             |
| ------------------------------- | --------------------------------------- |
| foreign_keys_map.sql            | Lists foreign key relationships         |
| search_column_database.sql      | Searches columns across database        |
| search_text_in_procedures.sql   | Searches text inside stored procedures  |
| stored_procedure_parameters.sql | Lists stored procedure parameters       |
| table_row_count.sql             | Retrieves estimated row count per table |

---

## monitoring/

Production monitoring and live diagnostics.

| Script                    | Description                         |
| ------------------------- | ----------------------------------- |
| active_connections.sql    | Displays active SQL Server sessions |
| blocking_sessions.sql     | Detects blocking chains             |
| long_running_requests.sql | Identifies long-running requests    |
| restore_history.sql       | Shows database restore history      |

---

## performance/

Performance tuning and bottleneck analysis.

| Script                    | Description                           |
| ------------------------- | ------------------------------------- |
| index_fragmentation.sql   | Analyzes index fragmentation          |
| missing_indexes.sql       | Detects potential missing indexes     |
| query_execution_stats.sql | Retrieves execution statistics        |
| stored_procedure.sql      | Analyzes stored procedure performance |
| top_expensive_queries.sql | Identifies high-cost queries          |

---

## quality/

SQL object quality and standards validation.

| Script                      | Description                                                    |
| --------------------------- | -------------------------------------------------------------- |
| sql_object_health_check.sql | Evaluates procedures/functions against SQL best-practice rules |

---

## storage/

Storage usage and capacity analysis.

| Script                  | Description                             |
| ----------------------- | --------------------------------------- |
| database_file_sizes.sql | Displays database file sizes and growth |
| largest_tables.sql      | Lists largest tables by size            |
| table_size.sql          | Calculates table space usage            |

---

# 🧠 Design Principles

Most scripts follow these principles:

- Prefer DMVs over deprecated objects
- Production-oriented diagnostics
- Readability over unnecessary complexity
- Safe analysis-first approach
- Focus on troubleshooting and operational support
- Reusable and adaptable queries

---

# ⚙️ Usage Notes

- Run scripts individually depending on the scenario
- Review generated commands before executing them in production
- Adapt filters and thresholds according to your environment
- Some scripts may require elevated permissions

---

# 📌 Why this repository exists

After years working with SQL Server in production systems, I found myself repeatedly building and refining the same types of operational scripts for:

- Troubleshooting production incidents
- Investigating performance degradation
- Understanding database structures
- Supporting deployments and maintenance
- Documenting legacy systems
- Reviewing SQL code quality

This repository is a structured version of those tools.

---

# 👨‍💻 About Me

Backend-focused developer with 10+ years of experience working with:

- C# / .NET
- SQL Server
- REST APIs
- Financial and transactional systems
- Performance optimization
- Production support environments

Currently expanding into data-oriented roles, including Data Engineering and Analytics Engineering.

---

# 🚧 Roadmap

Planned future additions:

- Query execution plan analysis
- Real-world optimization case studies
- SQL code review automation
- Data governance utilities
- ETL-oriented scripts
- Data quality validations

---

# 🤝 Contributions

Suggestions, improvements, and discussions are welcome.

If you find a script useful or have ideas to improve it, feel free to open an issue or pull request.

---
