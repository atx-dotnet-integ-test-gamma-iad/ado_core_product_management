# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removes certain APIs that were available in .NET Framework. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` compatibility shims if needed. Pay particular attention to:

- `System.Web` dependencies (not available in .NET Core/.NET 5+)
- Windows-only APIs (e.g., registry access, WCF server-side, Windows Forms)
- Any use of `AppDomain.CreateDomain` or `Thread.Abort`

Run the compatibility analyzer with:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

## 5. Validate NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure all packages target .NET Standard 2.0+ or the specific .NET version you are using. Replace any packages that only support .NET Framework with their modern equivalents.

```bash
dotnet list package --outdated
```

Update packages as needed:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 6. Test Runtime Behavior

Beyond compilation, verify runtime behavior by executing the application against a representative set of inputs or scenarios:

```bash
dotnet run --configuration Release --project AdoCore.csproj
```

Check application logs and output for any runtime exceptions, particularly around database connections, file I/O paths, or platform-specific operations.

## 7. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as `System.Configuration.ConfigurationManager` has limited support in cross-platform .NET. The `Microsoft.Extensions.Configuration` stack is the recommended replacement.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) based on your target environment.

## 9. Verify Output Artifacts

Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.