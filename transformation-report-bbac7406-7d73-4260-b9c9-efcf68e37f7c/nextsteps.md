# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed during the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the build output for any `CA1416` platform compatibility warnings. APIs that were available on .NET Framework may have been removed or may only be available on specific operating systems in cross-platform .NET.

You can also run the following to check for compatibility issues:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

## 5. Validate Runtime Behavior

Run the application and exercise its core functionality manually or through integration tests. Pay particular attention to:

- File path handling, as .NET on Linux and macOS uses case-sensitive paths.
- Configuration file loading, particularly if `app.config` or `web.config` files were used previously.
- Serialization and deserialization behavior, which may differ between runtimes.
- Any use of `System.Drawing`, `System.Web`, or other namespaces that have limited or no support in cross-platform .NET.

## 6. Review Target Framework

Open the `.csproj` file for `AdoCore` and confirm the target framework moniker (TFM) is set to an appropriate and supported version:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If you require long-term support, prefer `net8.0` over `net6.0` or `net7.0` at this time.

## 7. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier (`-r`) as needed for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment:

```bash
dotnet publish --configuration Release --self-contained true -r win-x64 --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to your target environment.