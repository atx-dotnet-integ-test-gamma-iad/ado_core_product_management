# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages previously targeting `.NET Framework` have cross-platform equivalents, replace them now.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated before proceeding further.

## 5. Check for Platform-Specific Code

Manually review the codebase for any APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET, including:

- `System.Web` references
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side code
- `AppDomain` usage beyond what is supported
- `BinaryFormatter` usage, which is disabled by default in modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility concerns.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators
- Case sensitivity in file system operations
- Environment variable differences across operating systems

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish -c Release
```

The output will be located in the `bin/Release/{TargetFramework}/publish/` directory. Verify the published output runs correctly in the target environment before distributing it.