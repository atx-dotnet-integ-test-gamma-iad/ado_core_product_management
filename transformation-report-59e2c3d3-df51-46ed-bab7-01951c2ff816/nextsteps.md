# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it still references a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and trace them back to behavioral differences introduced by the framework migration.

## 4. Check for Windows-Specific API Usage

Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or review the code manually for:

- `System.Windows.Forms` or `System.Drawing` usages
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific P/Invoke calls
- `System.Runtime.InteropServices` with platform-specific assumptions

Run the following to surface platform compatibility warnings:

```bash
dotnet build --configuration Release /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

## 5. Validate Runtime Behavior on Target Platform

If the goal is Linux or macOS compatibility, run the application directly on the target platform or use a compatible runtime environment:

```bash
dotnet run --configuration Release
```

Test all major code paths, particularly those involving file I/O, networking, or database access, as path separators and connection behaviors can differ across platforms.

## 6. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Open the `.csproj` file and cross-reference each `<PackageReference>` against the package's supported frameworks on [nuget.org](https://www.nuget.org).

Replace any packages that do not support the target TFM with maintained cross-platform alternatives.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Adjust the `--runtime` identifier (`linux-x64`, `win-x64`, `osx-x64`, etc.) to match your deployment target.