# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your development machine and any target deployment environments.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support the target framework. Check for `NU1701` warnings, which indicate a package was restored using a compatibility fallback and may not behave correctly at runtime.

## 3. Build the Solution

Perform a clean build to confirm there are no issues beyond what was reported:

```bash
dotnet clean
dotnet build --configuration Release
```

Review all warnings in the build output. Warnings related to obsolete APIs or platform compatibility (`CA1416`) should be addressed before deployment, particularly if the application is intended to run on non-Windows platforms.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and modern .NET, such as changes in globalization, reflection, or threading behavior.

## 5. Validate Platform-Specific Code

Search the codebase for APIs that were Windows-specific in .NET Framework and may not be available or may behave differently on Linux or macOS. Common areas include:

- `System.Drawing` (requires `libgdiplus` on non-Windows or use of an alternative package)
- `Microsoft.Win32.Registry`
- Windows Communication Foundation (WCF) server-side APIs
- `System.Security.Permissions` and Code Access Security (CAS)

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining platform-specific calls.

## 6. Test on Target Platforms

If cross-platform execution is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and environment variable differences across platforms.

## 7. Publish the Application

Once validation is complete, publish the application for your target environment. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output directory to confirm all required assets are present before deploying to the target environment.