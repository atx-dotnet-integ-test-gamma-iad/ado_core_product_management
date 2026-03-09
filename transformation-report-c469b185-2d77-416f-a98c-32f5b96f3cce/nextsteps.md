# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the value still references a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, such as platform-specific API usage.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET (e.g., changes in globalization, string handling, or reflection).

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to identify any remaining platform-specific API calls that may compile successfully but fail at runtime on non-Windows systems:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references
- P/Invoke calls targeting Windows-specific native libraries
- Registry access via `Microsoft.Win32.Registry`

## 5. Review NuGet Package Compatibility

Inspect all NuGet dependencies and confirm they support the target framework. Packages that have not been updated for cross-platform .NET may require replacement:

```bash
dotnet list package --outdated
```

Update packages where applicable:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that are not caught at compile time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate RID for your environment (e.g., `win-x64`, `osx-x64`). If a framework-dependent deployment is preferred, omit the `--self-contained` flag.

## 8. Review Output Artifacts

After publishing, verify the contents of the `publish` output directory to confirm all required assemblies, configuration files, and assets are present before deploying to the target environment.