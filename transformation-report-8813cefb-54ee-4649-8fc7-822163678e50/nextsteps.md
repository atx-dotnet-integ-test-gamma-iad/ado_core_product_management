# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support `.NET Framework` with their cross-platform equivalents where applicable.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings, particularly those related to platform compatibility (e.g., `CA1416` platform compatibility warnings), which may indicate APIs that do not function on non-Windows platforms.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between .NET Framework and modern .NET.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific API calls that may fail on Linux or macOS. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay attention to any `CA1416` warnings in the output.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to confirm runtime behavior is consistent. Use the following to publish a platform-specific binary:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true
dotnet publish -c Release -r win-x64 --self-contained true
dotnet publish -c Release -r osx-x64 --self-contained true
```

## 7. Review Configuration Files

Check that any configuration previously held in `App.config` or `Web.config` has been correctly migrated to `appsettings.json` or environment variables, as the `ConfigurationManager` API behaves differently in modern .NET.

## 8. Publish the Application

Once validation is complete, publish the final build:

```bash
dotnet publish -c Release -o ./publish
```

Verify the contents of the `./publish` directory and confirm all required runtime files and dependencies are present before deploying to the target environment.