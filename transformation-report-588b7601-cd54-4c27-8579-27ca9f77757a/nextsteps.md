# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore Dependencies

Run a full NuGet restore to ensure all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or have been deprecated.

---

## 3. Build the Solution

Perform a clean build to confirm there are no issues that were not surfaced during the initial transformation check:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to platform compatibility (e.g., `CA1416` platform-specific API warnings), as these can indicate code paths that will not function on non-Windows platforms.

---

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and modern .NET, such as changes in:
- `System.Data` ADO.NET behavior
- Connection string handling
- Exception types or messages

---

## 5. Validate ADO.NET Functionality

Since the project is named `AdoCore`, it likely contains data access logic. Manually verify the following:

- Database connection strings are compatible with the target database provider.
- The correct NuGet driver package is referenced (e.g., `Microsoft.Data.SqlClient` instead of the legacy `System.Data.SqlClient` where applicable).
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these have limited or no support on non-Windows platforms.

---

## 6. Check for Platform-Specific APIs

Run the .NET Compatibility Analyzer to detect any remaining platform-specific API usage:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to any APIs flagged as Windows-only, and replace or conditionally compile them as needed.

---

## 7. Test on Target Platform

If the goal is cross-platform support, run and test the application on the intended non-Windows platform (e.g., Linux or macOS):

```bash
dotnet run --configuration Release
```

Confirm that file paths, line endings, and any environment-specific configurations behave as expected.

---

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target. Review the publish output directory to confirm all required files are present.