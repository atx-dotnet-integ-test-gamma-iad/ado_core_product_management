# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Verify that no warnings or errors appear that could indicate incomplete migration artifacts.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to confirm existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET (e.g., changes in globalization, encoding defaults, or reflection behavior).

---

## 4. Check for Windows-Specific API Usage

Even without build errors, certain APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or the following command to surface platform-specific warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions

---

## 5. Validate ADO.NET / Database Connectivity

Since the project is named `AdoCore`, confirm that the database drivers in use are compatible with cross-platform .NET:

- Replace any `System.Data.SqlClient` references with `Microsoft.Data.SqlClient` (the cross-platform supported package).
- Verify connection strings do not rely on Windows Authentication in environments where it is not supported.
- Test actual database connections in a non-Windows environment if cross-platform execution is a goal.

```bash
dotnet add package Microsoft.Data.SqlClient
```

---

## 6. Review NuGet Package Compatibility

Check that all NuGet dependencies support the target framework. Run the following and inspect the output for any `NU1701` warnings (packages targeting .NET Framework being used in a .NET project):

```bash
dotnet restore --verbosity normal
```

Replace any packages flagged with `NU1701` with their cross-platform equivalents where available.

---

## 7. Test on Target Platform

If the intent is to run on Linux or macOS, perform a test run on that platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Then execute the published output on the target machine and verify runtime behavior matches expectations.

---

## 8. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been migrated to `appsettings.json` or environment-based configuration, as `System.Configuration.ConfigurationManager` behavior differs in cross-platform .NET and some features are not supported.