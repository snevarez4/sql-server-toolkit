# SQL Server Toolkit (Production-Oriented)

Collection of SQL Server scripts used in real-world environments for monitoring, performance tuning, and troubleshooting.

This is not a generic script dump.  
These scripts come from working with financial systems where performance, stability, and quick diagnosis matter.

---

## 🔍 What you’ll find here

Scripts organized by real use cases:

### Monitoring

- Active connections
- Blocking sessions

Used to quickly understand what is happening in a live system.

---

### Performance

- Index fragmentation analysis
- Expensive queries detection
- Stored procedure performance

Focused on identifying bottlenecks and optimization opportunities.

---

### Metadata

- Column search across database
- Row count by table
- Foreign key relationships

Useful for impact analysis and understanding data structures.

---

### Storage

- Table size and space usage

Helps identify heavy tables and storage distribution.

---

### Maintenance

- Index rebuild/reorganize recommendations

Designed for safe execution and controlled optimization.

---

## 🧠 Approach

Most scripts follow these principles:

- Avoid deprecated objects (use DMVs when possible)
- Safe for production analysis (read-first approach)
- Focus on clarity over cleverness
- Designed for troubleshooting, not just reporting

---

## ⚙️ How to use

- Run scripts individually depending on the scenario
- Review output before executing any generated commands
- Adapt filters (database, table, session) as needed

---

## 📌 Why this repository exists

After years working with SQL Server in production systems,  
I found myself reusing the same type of scripts for:

- Diagnosing performance issues
- Understanding database structure
- Supporting production incidents

This repository is a structured version of those tools.

---

## 👨‍💻 About me

Backend-focused developer with 10+ years of experience working with:

- C# / .NET
- SQL Server
- Financial systems (high reliability environments)

Currently expanding into data-focused roles (Data Engineering / Analytics).

---

## 🚧 Next steps

- Add real case studies (before/after optimization)
- Include execution plan analysis examples
- Expand into data-oriented scenarios

---
