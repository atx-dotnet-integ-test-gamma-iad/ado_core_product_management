# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment of the migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple target frameworks are required, use `<TargetFrameworks>` (plural) with a semicolon-separated list.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them in the `.csproj` file as needed.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not present during the initial transformation check:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests to determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET, such as changes in globalization, string handling, or reflection.

## 5. Check for Windows-Specific API Usage

Run the .NET Compatibility Analyzer to surface any remaining platform-specific API calls that may not behave correctly on Linux or macOS:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to diagnostics prefixed with `CA1416` (platform compatibility). Any flagged APIs should either be guarded with `OperatingSystem.IsWindows()` checks or replaced with cross-platform alternatives.

## 6. Validate Runtime Behavior

Execute the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

Pay attention to file path handling, line ending differences, and any environment-specific configuration that may have been hardcoded for Windows.

## 7. Review Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as `System.Configuration` support is limited in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release build:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output folder before distributing it.