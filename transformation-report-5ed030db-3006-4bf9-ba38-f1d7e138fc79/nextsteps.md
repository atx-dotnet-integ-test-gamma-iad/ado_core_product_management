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

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Windows-Specific API Usage

Even without build errors, certain APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or review the code manually for usage of:

- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- COM interop or P/Invoke calls targeting Windows-only libraries
- `AppDomain` features that are no longer supported

You can also run the following command to surface platform compatibility warnings:

```bash
dotnet build --configuration Release /p:EnableNETAnalyzers=true
```

## 5. Review NuGet Package Compatibility

Confirm that all NuGet dependencies referenced in `AdoCore.csproj` support the target framework. Open the `.csproj` file and cross-check each `<PackageReference>` against the package's supported frameworks on [nuget.org](https://www.nuget.org).

Replace any packages that do not support the new TFM with maintained equivalents.

## 6. Test on Target Platform

If the goal is cross-platform support, run the application on each intended operating system (e.g., Linux, macOS) to surface any runtime-only issues:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable access, and any OS-specific behavior in the codebase.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for Linux x64
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output.