# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that could not be resolved.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that may surface, particularly those related to obsolete APIs or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that existing behavior has been preserved after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences in the new runtime or by test setup issues.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the code manually for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., backslashes, drive letters)
- `AppDomain` usage

Run the following command to surface compatibility warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay attention to:

- File I/O operations and path separators
- Culture and encoding differences
- Any external process or COM interop calls

## 7. Review NuGet Package Versions

Confirm that all NuGet packages in use have versions compatible with the target framework. Check the [NuGet package compatibility page](https://www.nuget.org/) for any packages that may require upgrading.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (`win-x64`, `osx-x64`, etc.).