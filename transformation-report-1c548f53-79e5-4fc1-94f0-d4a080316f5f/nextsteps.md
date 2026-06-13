# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them to actively maintained equivalents.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete API usage, as these can indicate latent issues.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so test coverage is important at this stage.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET, including:

- `System.Web` namespaces
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage beyond what is supported
- COM interop or P/Invoke calls targeting Windows-only native libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Run on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that are not caught at compile time:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, line endings, and any environment-specific configuration.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output directory to confirm all required assets are present before deploying to the target environment.