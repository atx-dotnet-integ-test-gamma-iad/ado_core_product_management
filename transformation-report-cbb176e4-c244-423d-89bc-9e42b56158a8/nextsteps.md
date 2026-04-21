# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to your intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net4x` or `netstandard` targets unless that is intentional.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a clean build to confirm there are no hidden warnings or errors:

```bash
dotnet build --configuration Release
```

Address any warnings that may indicate compatibility issues, such as obsolete API usage or platform-specific calls.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test output carefully. Any failing tests should be investigated before proceeding.

## 5. Validate Runtime Behavior

Run the application locally and exercise its primary workflows:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Pay particular attention to:
- Database connectivity and ADO.NET operations, given the project name suggests ADO usage
- Any file I/O paths that may have been written with Windows-specific separators (`\`)
- Any calls to Windows-specific APIs (registry, COM interop, etc.) that may fail on non-Windows platforms

## 6. Check Platform-Specific Code

Search the codebase for APIs that may not be supported cross-platform:

- `System.Windows` namespaces
- `Microsoft.Win32` registry access
- P/Invoke calls to Windows DLLs
- `System.Drawing` (requires additional packages on Linux/macOS)

Use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to assist with this.

## 7. Review Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables where appropriate, as `ConfigurationManager` behavior differs in .NET compared to .NET Framework.

## 8. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that do not appear at compile time.

## 9. Publish the Application

Once validation is complete, publish the application for deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.