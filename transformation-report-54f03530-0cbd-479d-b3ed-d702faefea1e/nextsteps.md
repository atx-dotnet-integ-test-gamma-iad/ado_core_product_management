# Next Steps

The solution has no build errors following the transformation. The migration to cross-platform .NET appears to have completed successfully. The following steps outline how to validate, test, and deploy the project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, particularly around areas such as:

- `System.Configuration` usage
- Windows-specific APIs (e.g., registry access, WCF, Windows Forms)
- Globalization and encoding defaults
- Reflection behavior changes

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to identify any remaining platform-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to any APIs marked with `[SupportedOSPlatform("windows")]`.

## 5. Review Target Framework Moniker (TFM)

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If Windows-specific features are required, consider using:

```xml
<TargetFramework>net8.0-windows</TargetFramework>
```

## 6. Validate Configuration System

If the project previously used `App.config` or `Web.config` with `System.Configuration.ConfigurationManager`, verify that the `System.Configuration.ConfigurationManager` NuGet package has been added, or consider migrating configuration to `Microsoft.Extensions.Configuration`.

## 7. Verify Runtime Behavior

Run the application manually and exercise its primary workflows. Pay attention to:

- File path separators (use `Path.Combine` rather than hardcoded `\`)
- Case sensitivity on Linux/macOS file systems
- Thread culture and locale differences
- Any serialization or binary formatter usage, as `BinaryFormatter` is disabled by default in modern .NET

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate Runtime Identifier (RID) for your target platform (e.g., `linux-x64`, `osx-x64`).

## 9. Review Published Output

Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present before distributing or deploying the output.