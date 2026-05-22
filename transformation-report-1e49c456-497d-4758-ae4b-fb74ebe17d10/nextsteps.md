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

Ensure there are no warnings that could indicate compatibility issues with the target platform.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Pay particular attention to any usage of:
- `Microsoft.Win32` registry APIs
- Windows-specific `System.Drawing` (GDI+)
- COM interop or P/Invoke calls targeting Windows DLLs
- `System.Web` types

## 5. Run the Application on the Target Platform

If the intent is to run on Linux or macOS, execute the application on that platform directly to catch any runtime-only issues:

```bash
dotnet run --configuration Release
```

Alternatively, publish a self-contained binary for the target runtime and test it:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true
```

## 6. Review NuGet Package Compatibility

Check that all NuGet dependencies support the new target framework. Packages that only support `net4x` may have been included via compatibility shims. Confirm each package explicitly supports your chosen TFM by reviewing its entry on [nuget.org](https://www.nuget.org).

## 7. Validate Configuration and App Settings

If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, as `ConfigurationManager` behavior differs under cross-platform .NET.

## 8. Publish the Application

Once all validation steps pass, publish the application for the intended target:

```bash
dotnet publish -c Release -r <runtime-identifier> --self-contained false -o ./publish
```

Replace `<runtime-identifier>` with the appropriate value, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the contents of the `./publish` output directory before deploying to the target environment.