# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently or are unavailable at runtime on cross-platform .NET. Pay particular attention to:

- **Windows-only APIs**: Any use of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32.Registry`, or P/Invoke calls targeting Windows-specific libraries may fail on non-Windows platforms. Use the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify these.
- **AppDomain usage**: Some `AppDomain` members are no longer supported.
- **Reflection and serialization**: Behavior differences exist in `BinaryFormatter` (which is now disabled by default) and certain reflection scenarios.

## 5. Review NuGet Package Versions

Confirm that all NuGet dependencies reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and verify that no packages still target `net45`, `net461`, or other legacy monikers exclusively.

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, verify that settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy `ConfigurationManager` API is available via the `System.Configuration.ConfigurationManager` NuGet package if needed, but migrating to `Microsoft.Extensions.Configuration` is recommended.

## 7. Perform Functional Testing

Execute the application manually or through integration tests and exercise the primary workflows. Compare the output and behavior against the legacy version to confirm correctness.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assets, configuration files, and dependencies are present before deploying to the target environment.