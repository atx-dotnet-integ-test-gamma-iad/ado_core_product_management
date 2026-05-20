# Next Steps

The transformation appears to have completed successfully. There are no build errors reported across any of the projects in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other unintended frameworks.

## 2. Restore Dependencies

Run the following command from the solution root to restore all NuGet packages:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages and update them as needed using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate subtle compatibility issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime, such as differences in:

- `System.Drawing` (not fully supported cross-platform without additional packages like `System.Drawing.Common`)
- `System.Security` APIs
- Registry access or Windows-specific APIs
- `HttpWebRequest` vs `HttpClient` behavior

## 5. Check for Windows-Specific API Usage

If the intent is to run on non-Windows platforms, audit the code for Windows-specific APIs. You can enable platform compatibility analysis by adding the following to each `.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Build again and review any `CA1416` (platform compatibility) warnings.

## 6. Run the Application

Execute the application directly to perform a basic smoke test:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Verify that the application starts and behaves as expected. Test the primary workflows manually if automated tests do not provide full coverage.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting a specific platform, use:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

Or for a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

The output will be placed in the `bin/Release/<framework>/publish/` directory. Verify the published output runs correctly in the target environment before promoting it to production.