# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore NuGet Packages

Run the following command from the solution root to confirm all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a clean build to confirm there are no issues beyond what was reported:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent runtime issues.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify functional correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee behavioral correctness, so test coverage is important at this stage.

## 5. Validate Platform-Specific Behavior

Since this is a cross-platform migration, run the application on each target operating system (Windows, Linux, macOS) if applicable. Pay particular attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Case sensitivity in file and directory names
- Any use of Windows-specific registry, COM interop, or P/Invoke calls

Search the codebase for `RuntimeInformation.IsOSPlatform` usage or any `#if WINDOWS` directives to understand what platform guards are already in place.

## 6. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs used in the project that have been removed or changed in the target .NET version:

```bash
dotnet tool install -g dotnet-apicompat
```

This is particularly relevant if the original project targeted .NET Framework.

## 7. Review Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables as appropriate for the new hosting model.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require .NET to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your target environment.

## 9. Verify the Published Output

Navigate to the publish output directory and run the application directly to confirm it starts and behaves as expected in its published form before distributing or deploying it.