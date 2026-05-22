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

Ensure there are no warnings that could indicate runtime issues, such as platform compatibility warnings (`CA1416`).

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in `System.Data`, encoding defaults, or globalization behavior).

---

## 4. Check for Windows-Specific API Usage

Use the .NET Compatibility Analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining Windows-specific API calls. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to:
- `System.Data.OleDb` (Windows-only)
- `Microsoft.Win32` registry access
- COM interop calls
- `System.Drawing` (requires `System.Drawing.Common` and may have platform restrictions)

---

## 5. Validate ADO.NET Functionality

Since the project is named `AdoCore`, confirm that all database connectivity works as expected on the target platform:

- Verify that the correct NuGet packages are referenced for your database provider (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`).
- Test connection strings and confirm they resolve correctly in the new environment.
- Confirm that any `DataSet`, `DataTable`, or `DataAdapter` usage behaves as expected, as some edge cases differ between .NET Framework and cross-platform .NET.

---

## 6. Review `app.config` / `web.config` Migration

Cross-platform .NET does not use `app.config` or `web.config` in the same way as .NET Framework. Confirm that:

- Connection strings have been moved to `appsettings.json` or environment variables if applicable.
- Any `<configSections>` or custom configuration handlers have been replaced with `Microsoft.Extensions.Configuration`.

---

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

If targeting a specific platform, use the `-r` flag with a Runtime Identifier (RID):

```bash
dotnet publish --configuration Release -r linux-x64 --self-contained true --output ./publish
```

Verify the output in the `./publish` directory runs correctly on the target machine or operating system.