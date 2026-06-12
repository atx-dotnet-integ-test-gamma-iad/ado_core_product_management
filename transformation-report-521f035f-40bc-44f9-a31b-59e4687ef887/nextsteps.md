# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the value still references a Windows-only framework such as `net472` or `net48`, update it accordingly.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output and investigate any failing tests to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Windows-Specific API Usage

Even without build errors, certain APIs that compiled successfully may not behave correctly or may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the following command to check for platform-specific API usage:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop (`DllImport` targeting Windows-only DLLs)

## 6. Run the Application and Perform Smoke Testing

Execute the application manually and verify that core functionality works as expected:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Walk through the primary use cases of the application to confirm runtime behavior matches the legacy version.

## 7. Validate Data Access Behavior

Since the project name suggests ADO.NET usage (`AdoCore`), verify that all database connections, queries, and transactions function correctly against your target database. Confirm that connection strings have been updated if necessary and that the ADO.NET provider packages (e.g., `Microsoft.Data.SqlClient`) are the cross-platform compatible versions rather than legacy `System.Data.SqlClient` references where applicable.

## 8. Review Output Artifacts

Check that the build output is producing the correct artifact type (executable or library) and that all necessary files are present in the output directory:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to confirm all dependencies are included and the output is self-consistent.